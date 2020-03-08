const fs = require('fs');
const path = require('path');
const nodemailer = require('nodemailer');

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

    fastify.get('/mail', async (req, res) => {  //getting account info/ checking if username/psw is correct
        var transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: 'elmwebsitemailer@gmail.com',
                pass: 'supersecret'
            }
        });

        var mailOptions = {
            from: 'elmwebsitemailer@gmail.com',
            to: 'jurajbedej1@yahoo.com',
            subject: 'Account activation',
            text: 'Activate your account by using the following code:'
        };

        transporter.sendMail(mailOptions, function(error, info){
            if (error) {
                console.log(error);
            } else {
                console.log('Email sent: ' + info.response);
            }
        });

    })

    fastify.get('/db', async (req, res) => {  //image database
        
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        returnJson = require('./db.json')
        res.send(returnJson)

    })

    fastify.post('/sign_up', async (req, res) => {    //registering new account
        res.header("Access-Control-Allow-Origin", "*")  //allows sharing the resource
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        //res.Header('Access-Control-Allow-Methods', 'POST, OPTIONS');
        //res.Header('Access-Control-Allow-Headers', 'X-Requested-With,content-type');
        //res.Header('Access-Control-Allow-Credentials', true);
        console.log(req.body)
        console.log("A new account has been registered")
        res.send({ response : "Account successfully created" })
        //returnJson = require('./db.json')
        //res.send(returnJson)
    })

    fastify.post('/upload', async(req, res) => {
        console.log("Uploading a file to the server")
    })

    fastify.post('/sign_in', async(req, res) => {
        console.log("User attempting to sign in")
    })

    fastify.patch('/testPatch', async (req, res) => {  //changing account settings
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        //returnJson = {name:req.params.kulo}
        console.log("PATCHING...");
        //res.send(returnJson)

    })


}

module.exports = routes