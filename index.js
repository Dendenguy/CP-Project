const swipl = require('./swipl/index');
const express = require('express')
const bodyParser = require("body-parser")
const app = express()
const port = process.env.PORT || 8080;

app.use(bodyParser.json())
app.use(express.static("public"))

function parsePrologResult(prologResult) {
    let result = {}
    result.schedule = prologResult.Schedule.map(t => t.map((s) => {return {from: s.args[0], to: s.args[1], departureTime: s.args[2], arrivalTime: s.args[3]}}))
    result.tardiness = prologResult.Tardiness
    return result
}

app.post('/schedule', async (req, res) => {
    try {
        const edges = req.body.edges, trains = req.body.trains, vertices = req.body.vertices
        const engine = new swipl.Engine();
        await engine.call('[train_scheduler]')
        await engine.call(`assert(vertices([${vertices.join(",")}]))`)
        for (let edge of edges) {
            await engine.call(`assert(edge(${edge.from}, ${edge.to}, ${edge.length}, ${edge.type}))`)
            await engine.call(`assert(edge(${edge.to}, ${edge.from}, ${edge.length}, ${edge.type}))`)
        }
        for (let i = 0; i < trains.length; i++) {
            let train = trains[i]
            await engine.call(`assert(train(${train.id}, ${train.releaseTime}, ${train.dueTime},${train.from}, ${train.to}))`)
        }
        await engine.call(`assert(num_trains(${trains.length}))`)
        

        console.log("================================================")
        console.log(new Date())
        console.dir(trains, {depth: 1000})
        console.dir(edges, {depth: 1000})

        const timeout = setTimeout(() => {
            engine.close()
            res.send({success: false, error: "Prolog query took too long to complete."})
            console.log("Timeout")
            console.log("================================================")
        }, 1.5*60*1000)
        
        let result = await engine.call("schedule_trains(Schedule, Tardiness)")
        
        if (!engine.state.isClosed()) {
            clearTimeout(timeout)
            if (result) {
                result = parsePrologResult(result)
                console.dir(result, {depth: 1000})
                res.send({success: true, result: result})
            } else {
                res.send({success: false, error: "Failed to schedule the trains as the prolog goal failed."})
                console.log("Result: false")
            }
            console.log("================================================")
        }        
        
    } catch(error) {
        if (!res.headersSent) {
            res.send({success: false, error: "Internal Server Error: " + error.message})
        }
        console.log(error)
    }
})

app.listen(port, () => console.log(`App started on port ${port}!`))