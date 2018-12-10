const swipl = require('swipl-stdio');
// Engine represents one SWI-Prolog process.
const engine = new swipl.Engine();
(async () => {
    const result = await engine.call('member(X, [1,2,3,4])');
    if (result) {
        console.log(`Variable X value is: ${result.X}`);
    } else {
        console.log('Call failed.');
    }
    // Either run more queries or stop the engine.
    engine.close();
})().catch((err) => console.log(err));