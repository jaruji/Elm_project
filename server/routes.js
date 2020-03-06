const fs = require('fs');

async function routes(fastify) {

    fastify.get('/helloWorld', async function (request, reply) {
        setImmediate(() => {
            reply.send({ hello: 'world' })
        })
    //return reply
    })
    
    fastify.get('/accounts', async (req, res) => {  //getting account info/ checking if username/psw is correct
        
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        returnJson = require('./accounts.json')
        res.send(returnJson)

    })

    fastify.get('/db', async (req, res) => {  //image database
        
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        returnJson = require('./db.json')
        res.send(returnJson)

    })

    fastify.post('/:sign_up', async (req, res) => {    //registering new account
        console.log("A new account has been registered")
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        //returnJson = require('./db.json')
        //res.send(returnJson)

    })

    fastify.patch('/:testPatch', async (req, res) => {  //changing account settings
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        //returnJson = {name:req.params.kulo}
        console.log("PATCHING...");
        //res.send(returnJson)

    })


}

module.exports = routes