const fs = require('fs');
const {pipeline} = require("stream");
const path = require('path');
const nodemailer = require('nodemailer');
const MongoClient = require('mongodb').MongoClient;
const assert = require('assert')
const gpc = require('generate-pincode')
const crypto = require('crypto')
var Busboy = require('busboy');

const url = 'mongodb://localhost:27017';

//TODO: remove db overhead, stay connected to database at all times? :) 

function INSERT(dbName, obj){
    MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
    async function(err, client) {
        assert.equal(null, err);
        var db = client.db("database");
        var cursor = await db.collection(dbName).insertOne(obj);
        client.close();
    });
}

function getAllByKey(dbName, key){
    MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
        assert.equal(null, err);
        var db = client.db("database");
        var cursor = await db.collection(dbName).distinct(key)
        console.log(cursor)
        client.close()
    });
}

async function getUserByToken(token){
    var ret
    MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
        assert.equal(null, err);
        var db = client.db("database");
        var cursor = await db.collection("accounts").find({token: token}).toArray(async function(err, docs){
            ret = docs[0].username
            client.close()
            return ret;
        })
    })
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
    obj.secretKey = null
    obj.token = crypto.randomBytes(48).toString('hex')
    return obj
}

function createImage(obj){
    obj.upvotes = 0
    obj.downvotes = 0
    obj.views = 0
    //obj.comments = null
    //obj.commentCount = 0 //so we can show comment count without sending all coments
    obj.uploaded = new Date()
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
                    res.code(400).send(new Error("Invalid creditentials"))
                }
                else{
                    //hide properties that are not necessary/security risk!
                    delete docs[0]._id
                    delete docs[0].password
                    delete docs[0].verifCode
                    delete docs[0].secretKey
                    delete docs[0].twoFactor
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
                    res.code(400).send(new Error("Invalid token"))
                }
                else{
                    //hide properties that are not necessary/security risk!
                    delete docs[0]._id
                    delete docs[0].password
                    delete docs[0].verifCode
                    delete docs[0].secretKey
                    delete docs[0].twoFactor
                    res.send(docs[0])
                }
                client.close()
            })
        });
    })

    fastify.post('/account/user', async(req, res) => {
        //return only public user info! input is username, returns
        let username = req.body.username
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find({username: username}).toArray(function(err, docs){
                if(docs.length === 0){
                    res.code(400).send(new Error("This profile does not exist"))
                }
                else{
                    //hide properties that are not necessary/security risk!
                    delete docs[0]._id
                    delete docs[0].password
                    delete docs[0].verifCode
                    delete docs[0].email
                    delete docs[0].token
                    delete docs[0].twoFactor
                    res.send(docs[0])
                }
                client.close()
            })
        });
    })

    fastify.patch('/account/update', async(req, res) => {
        let auth = req.headers.auth
        res.code(200).send()
    });

    //upload files to the server by posting to this url
    fastify.put('/upload/image', async(req, res) => {
        let dir = "./server/data/img"
        let auth = req.headers.auth
        let title = req.headers.title
        let tags = req.headers.tags
        let description = req.headers.description
        var username
        console.log("Uploading a file to the server")
        let ID = crypto.randomBytes(10).toString('hex')
        filename = ID + path.extname(req.headers.name);
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').findOne({token: auth})
            let obj = {id: ID, file: filename, title:title, description:description, author:cursor.username, tags:tags.substring(1, tags.length-1).replace(/"/g,'').split(",")}
            var insert = await db.collection('images').insertOne(createImage(obj))
            client.close();
        })
        pipeline(
          req.body,
          fs.createWriteStream(`${dir}/${filename}`),
          (err) => {
            if(err){
              console.log("Error during writing file");
              fs.unlinkSync(`${dir}/${filename}`);      //delete file if error occured
              res.code(400).send(new Error("Error during writing file"))
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
        dir = "./server/data/img/profile/"
        pipeline(                                 //store initial file to specified directory
          req.body,
          fs.createWriteStream(`${dir}/${filename}`),
          (err) => {
            if(err){
              console.log("Error during writing file, deleting...");
              fs.unlinkSync(`${dir}/${filename}`);      //delete file if error occured
              res.code(400).send(new Error("Error during writing file"))
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

    fastify.post('/accounts/query', async(req, res) => {
        let query = req.body.query
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('accounts').find({"username": {$regex: query, $options: 'i'}}).sort().toArray()
            let output = cursor.map(({_id, registeredAt, password, token, email, verifCode, bio, firstName, surname, facebook, twitter, github, occupation, age, twoFactor, history, ...rest}) => rest)
            res.send(output)
            client.close()
        });
    })
    
    fastify.post('/images/get', async (req, res) => {  //image database
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('images').find().sort(req.body).toArray()
            let output = cursor.map(({_id, description, tags, comments, ...rest}) => rest)
            output.map(function(key){
                key["file"] = "http://localhost:3000/img/" + key.file
            })
            res.send(output)
            client.close()
        });
    })

    fastify.post('/images/id', async (req, res) => {  //image database
        let id = req.body.id
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true}, async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var view = await db.collection('images').updateOne({id: id}, {$inc:{views: 1}})
            var cursor = await db.collection('images').findOne({id: id})
            delete cursor._id
            cursor.file = "http://localhost:3000/img/" + cursor.file
            res.send(cursor)
            client.close()
        });
    })

    fastify.post('/images/comment', async (req, res) => {  //image database
        let content = req.body.content
        let username = req.body.username
        let avatar = req.body.url
        let id = req.body.id
        MongoClient.connect(url, {useNewUrlParser:true, useUnifiedTopology:true},
        async function(err, client) {
            assert.equal(null, err);
            var db = client.db("database");
            var cursor = await db.collection('images').updateOne({id: id}, {$push: {comments: {username: username, url: avatar, content:content, date: new Date()}}})
            res.code(200).send()
            client.close()
        })
    })

}

module.exports = routes