const fs = require('fs');
const {pipeline} = require("stream");
const path = require('path');
const nodemailer = require('nodemailer');
const MongoClient = require('mongodb').MongoClient;
const assert = require('assert')
const gpc = require('generate-pincode')
const crypto = require('crypto')

const url = 'mongodb://localhost:27017';

function INSERT(dbName, obj){
    MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
    async function(err, client) {
        assert.equal(null, err);
        var db = client.db("database");
        var cursor = await db.collection(dbName).insertOne(obj);
        client.close();
    });
}

function createAccount(obj){
    obj.verif = false
    obj.verifCode = gpc(6)
    obj.profilePic = null//"http://localhost:3000/img/profile/default.jpg"
    obj.history = []
    obj.bio = null
    obj.firstName = null
    obj.surname = null
    obj.occupation = null
    obj.facebook = null
    obj.twitter = null
    obj.github = null
    obj.registeredAt = new Date()
    obj.age = null
    obj.twoFactor = false
    obj.token = crypto.randomBytes(48).toString('hex')
    return obj
}

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

    fastify.post('/account/sign_up', async (req, res) => {    //registering new account
        res.header("Access-Control-Allow-Origin", "*")  //allows sharing the resource
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        let obj = createAccount(req.body)
        console.log(obj)
        INSERT("accounts", obj)
        console.log("A new account has been registered")
        res.send({ response : "OK" })
    })

    //used for validating log in creditentials
    fastify.post('/account/validate', async(req, res) => {
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
        });
    })

    fastify.post('/mailer/send', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        let code = gpc(6)
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').updateOne(req.body, {$set: {verifCode: code}})
            client.close()
        });
        console.log("Sending mail to " + req.body.email)
        sendActivationMail(req.body.email, code)
        res.send({response: true})
    })

    fastify.post('/account/verify', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find(req.body).toArray(async function(err, docs){
                if(docs.length === 0){
                    console.log(docs)
                    res.send({response: false})
                }
                else{
                    var temp = await db.collection('accounts').updateOne(req.body, {$set: {verif: true, verifCode: null}})
                    res.send({response: true})
                }
                client.close()
            })
        });
    })


    fastify.post('/account/sign_in', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find(req.body).toArray(function(err, docs){
                if(docs.length === 0){
                    console.log(docs)
                    res.code(400).send()
                }
                else{
                    //hide properties that are not necessary/security risk!
                    delete docs[0]._id
                    delete docs[0].password
                    delete docs[0].verifCode
                    //console.log(docs)
                    res.send(docs[0])
                }
                client.close()
            })
        });
    })

    fastify.get('/account/auth', async(req, res) => {
        let auth = req.headers.auth
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find({token: auth}).toArray(function(err, docs){
                if(docs.length === 0){
                    res.code(400).send()
                }
                else{
                    //hide properties that are not necessary/security risk!
                    delete docs[0]._id
                    delete docs[0].password
                    delete docs[0].verifCode
                    res.send(docs[0])
                }
                client.close()
            })
        });
    })

    fastify.patch('/account/update', async(req, res) => {
        let auth = req.headers.auth
        /*
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find().toArray(async function(err, docs){
                if(docs.length === 0){
                    console.log(docs)
                    res.code(400).send()
                }
                else{
                    var cursor = await db.collection('accounts').updateOne({token: auth}, {$set: req.body})
                    res.code(200).send()
                }
            })
            client.close()
        })    */
        res.code(200).send()
    });

    //upload files to the server by posting to this url
    fastify.put('/upload/image', async(req, res) => {
        let dir = "./data/img"
        console.log("Uploading a file to the server")
        filename = req.headers.name;           //get name of received file
        pipeline(                                 //store initial file to specified directory
          req.body,
          fs.createWriteStream(`${dir}/${filename}`),
          (err) => {
            if(err){
              console.log("Error during writing file");
              fs.unlinkSync(`${dir}/${filename}`);      //delete file if error occured
              res.code(400).send()
              return;
            }
            else{
                console.log(`File stored to ${dir}/${filename}`)
                res.code(200).send()
            }
          }
        )
    })

    
    fastify.put('/upload/profile', async(req, res) => {
        user = req.headers["user"];
        filename = user + path.extname(req.headers["name"]);    //get name of received file
        let link = "http://localhost:3000/img/profile/" + filename
        dir = "./data/img/profile/"
        pipeline(                                 //store initial file to specified directory
          req.body,
          fs.createWriteStream(`${dir}/${filename}`),
          (err) => {
            if(err){
              console.log("Error during writing file, deleting...");
              fs.unlinkSync(`${dir}/${filename}`);      //delete file if error occured
              res.code(400).send()
              return;
            }
            else{
                console.log(`File stored to ${dir}/${filename}`)
                MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
                    assert.equal(null, err);
                    var db = client.db("database");
                    //here I should delete the previous file
                    var cursor = await db.collection('accounts').updateOne({username: user}, {$set: {profilePic: link}})
                    client.close()
                });
                res.send({response: link}) //respond with updated image link!
            }
          }
        )

    })

    
    fastify.get('/img', async (req, res) => {  //image database
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        res.send({file: "http://localhost:3000/img/pexels-photo-736230.jpeg"})

    })
}

module.exports = routes