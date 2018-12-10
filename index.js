const swipl = require('swipl-stdio');

const express = require('express')
const app = express()
const port = process.env.PORT || 8080;

app.get('/', async (req, res) => {
    try {
        const engine = new swipl.Engine();
        const result = await engine.call('member(X, [1,2,3,4])');
        if (result) {
            res.send(`Variable X value is: ${result.X}`);
            console.log("Success!");
        } else {
            res.send('Call failed.');
            console.log("Failure.")
        }
        // Either run more queries or stop the engine.
        engine.close();
    } catch(error) {
        res.send(error)
        console.log(error)
    }
})

app.listen(port, () => console.log(`App listening on port ${port}!`))