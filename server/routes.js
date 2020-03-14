const fs = require('fs');
const {pipeline} = require("stream");
const path = require('path');
const nodemailer = require('nodemailer');
const MongoClient = require('mongodb').MongoClient;
const assert = require('assert')
const gpc = require('generate-pincode')

const url = 'mongodb://localhost:27017';

//command to start mongDB serv: mongod --dbpath /c/Users/6430u/Desktop/Webpage/server/data/db


function INSERT(dbName, obj){
    MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
    async function(err, client) {
        assert.equal(null, err);
        console.log("Successfully connected to the database");
        var db = client.db("database");
        var cursor = await db.collection(dbName).insertOne(obj);
        /*
        var something = await db.collection('accounts').find().toArray(function(err, docs){
            console.log(docs);
        })*/
        client.close();
    });
}

async function printAll(dbName){
    MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
    async function(err, client) {
        assert.equal(null, err);
        console.log("Successfully connected to the database");
        var db = client.db("database");
        var cursor = await db.collection('accounts').find().toArray(function(err, docs){
            console.log(docs);
        })
        //client.close();
    });
}

//printAll("accounts")

function findDuplicate(dbName, obj){
    //im fucking done with this trash ass shit
}

//findDuplicate("accounts", { username: "otto" })
//findDuplicate("accounts", { username: "jaruji" })

function sendActivationMail(receiver, code){
    var transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: 'elmwebsitemailer@gmail.com',
            pass: 'supersecret'
        }
    });

    var mailOptions = {
        from: 'elmwebsitemailer@gmail.com',
        to: receiver,
        subject: 'Account activation',
        text: 'Activate your account by using the following code: ' + code
    };

    transporter.sendMail(mailOptions, function(error, info){
        if (error) {
            console.log(error);
        } else {
            console.log('Email sent: ' + info.response);
        }
    });
}

async function routes(fastify) {
    
    fastify.get('/accounts', async (req, res) => {  //getting account info/ checking if username/psw is correct
        
        //res.header("Access-Control-Allow-Origin", "*")
        //res.header("Access-Control-Allow-Headers", "X-Requested-With")
        returnJson = require('./accounts.json')
        res.send(returnJson)

    })

    fastify.get('/img', async (req, res) => {  //image database
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        //returnJson = require('./db.json')
        //res.send(returnJson)
        res.send({file: "http://localhost:3000/img/pexels-photo-736230.jpeg"})

    })

    fastify.post('/sign_up', async (req, res) => {    //registering new account
        res.header("Access-Control-Allow-Origin", "*")  //allows sharing the resource
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        req.body.verif = false;
        req.body.verifCode = gpc(6)
        console.log(req.body)
        //INSERT("accounts", req.body)
        console.log("A new account has been registered")
        //console.log("Activation code expected: " + req.body.verifCode);
        //don't send mails while testing, no point
        //sendActivationMail(req.body.email)
        res.send({ response : "OK" })
        //returnJson = require('./db.json')
        //res.send(returnJson)
    })

    fastify.post('/verify', async(req, res) => {

    })

    //upload files to the server by posting to this url
    fastify.post('/upload', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        let dir = "data/db/img"
        console.log("Uploading a file to the server")
        filename = req.headers["name"];           //get name of received file
        pipeline(                                 //store initial file to specified directory
          req,
          fs.createWriteStream(`${dir}/${filename}`),
          (err) => {
            if(err){
              console.log("Error during writing file");
              fs.unlinkSync(`${dir}/${filename}`);      //delete file if error occured
              res.send({ response: "Error" })
              return;
            }
            else{
              console.log(`File stored to ${dir}/${filename}`)
              res.send({ response : "OK" })
            }
          }
        )
    })

    //used for validating log in creditentials
    fastify.post('/validate', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find(req.body).toArray(function(err, docs){
                if(docs.length === 0)
                    res.send({response: "Error"})
                else
                    res.send({response: "OK"})
                client.close()
            })
            //client.close()
        });
    })
}

module.exports = routes