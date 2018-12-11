const swipl = require('./swipl/index');
const express = require('express')
const app = express()
const port = process.env.PORT || 8080;

const vertices = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'l', 'm', 'k']
const trains = [
    [0, 240, ['f', 'e', 'd', 'c', 'b', 'a']],
    [60, 270, ['i', 'h', 'g', 'd', 'c', 'b', 'a']],
    [30, 210, ['i', 'h', 'j', 'l', 'm']],
    [60, 300, ['m', 'l', 'k', 'c', 'b', 'a']],
    [180, 360, ['a', 'b', 'c', 'd', 'g', 'h', 'j']],
    [120, 330, ['a', 'b', 'c', 'd', 'e', 'f']],
    [90, 240, ['c', 'k', 'l', 'm']]
]

const edges = [
    ['a', 'b', 40, 1],
    ['b', 'c', 40, 2],
    ['c', 'k', 60, 1],
    ['c', 'd', 50, 1],
    ['d', 'e', 35, 1],
    ['e', 'f', 35, 1],
    ['d', 'g', 30, 1],
    ['g', 'h', 30, 1],
    ['h', 'i', 25, 1],
    ['h', 'j', 30, 2],
    ['j', 'l', 60, 2],
    ['m', 'l', 20, 1],
    ['l', 'k', 60, 1]
]
async function test() {
    const engine = new swipl.Engine();
    await engine.call('[project_cp]')
    await engine.call(`assert(vertices([${vertices.join(",")}]))`)
    for (let edge of edges) {
        await engine.call(`assert(edge(${edge.join(",")}))`)
        await engine.call(`assert(edge(${edge[1]}, ${edge[0]},${edge[2]},${edge[3]}))`)
    }
    for (let i = 0; i < trains.length; i++) {
        let train = trains[i]
        await engine.call(`assert(train(${i+1}, ${train[0]}, ${train[1]},[${train[2].join(",")}]))`)
    }
    await engine.call(`assert(num_trains(${trains.length}))`)

    let result = await engine.call("schedule_trains(L, S)")
    return JSON.stringify(result)

}

app.use(express.static("public"))

app.get('/', async (req, res) => {
    try {
        res.send(await test())
    } catch(error) {
        res.send(error)
        console.log(error)
    }
})

app.listen(port, () => console.log(`App listening on port ${port}!`))