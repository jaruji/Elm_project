const fs = require('fs');
const {pipeline} = require("stream");
const path = require('path');
const nodemailer = require('nodemailer');
const MongoClient = require('mongodb').MongoClient;
const assert = require('assert')
const gpc = require('generate-pincode')
const crypto = require('crypto')

const url = 'mongodb://localhost:27017';
const client = new MongoClient(url, {useNewUrlParser:true, useUnifiedTopology:true})
const connection = client.connect()

function createAccount(obj){
    obj.verif = false
    obj.verifCode = gpc(6)
    obj.profilePic = null
    obj.history = null
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
    obj.points = 0
    obj.views = 0
    obj.uploaded = new Date()
    return obj
}

function sendActivationMail(receiver, code){
    var transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: 'elmwebsitemailer@gmail.com',
            pass: 'supersecret' //need to somehow hide these
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
        //log = user has created his account
        res.header("Access-Control-Allow-Origin", "*")  //allows sharing the resource
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db('database')
        let insert = db.collection('accounts').insertOne(createAccount(req.body))
        res.send({ response : "OK" })
    })

    //used for validating log in creditentials
    fastify.post('/account/validate', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db('database')
        var cursor = await db.collection('accounts').find(req.body).toArray(function(err, docs){
            if(docs.length === 0)
                res.send({response: "Error"})
            else
                res.send({response: "OK"})
        })
    })

    fastify.post('/mailer/send', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        let code = gpc(6)
        const db = client.db('database')
        var cursor = await db.collection('accounts').updateOne(req.body, {$set: {verifCode: code}})
        client.close()
        sendActivationMail(req.body.email, code)
        res.send({response: true})
    })

    fastify.post('/account/verify', async(req, res) => {
        //log this: user has verified his account
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db('database')
        var cursor = await db.collection('accounts').find(req.body).toArray(async function(err, docs){
            if(docs.length === 0){
                console.log(docs)
                res.send({response: false})
            }
            else{
                var temp = await db.collection('accounts').updateOne(req.body, {$set: {verif: true, verifCode: null}})
                res.send({response: true})
            }
        }) 
    })


    fastify.post('/account/sign_in', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db('database')
        var cursor = await db.collection('accounts').find(req.body).toArray(function(err, docs){
            if(docs.length === 0){
                res.code(400).send(new Error("Invalid creditentials"))
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
        })
    })

    fastify.get('/account/auth', async(req, res) => {
        let auth = req.headers.auth
        const db = client.db('database')
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
        })
    })

    fastify.post('/account/user', async(req, res) => {
        //return only public user info! input is username, returns
        let username = req.body.username
        const db = client.db('database')
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
        })
    })

    fastify.post('/account/posts', async(req, res) => {
        //get preview of user's posts
        let author = req.body.username
        const db = client.db('database')
        var cursor = await db.collection('images').find({author: author}).sort({uploaded: -1}).limit(req.body.limit).toArray()
        let output = cursor.map(({_id, description, tags, comments, upvotes, downvotes, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        res.send(output)
    });

    fastify.get('/posts/latest', async(req, res) => {
        //get preview of user's posts
        const db = client.db('database')
        var cursor = await db.collection('images').find().sort({uploaded: -1}).limit(5).toArray()
        let output = cursor.map(({_id, description, tags, comments, upvotes, downvotes, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        res.send(output)
    });

    fastify.patch('/account/update', async(req, res) => {
        //log this = user has updating his personal settings
        let auth = req.headers.auth
        let bio = req.body.bio
        let firstName = req.body.firstName
        let surname = req.body.surname
        let occupation = req.body.occupation
        let facebook = req.body.facebook
        let twitter = req.body.twitter
        let github = req.body.github
        const db = client.db('database')
        let cursor = db.collection('accounts').updateMany({token: auth}, {$set:{bio: bio, firstName: firstName, surname: surname, occupation:occupation, facebook:facebook, twitter:twitter, github:github}})
        res.code(200).send()
        //TODO Update all changes
    });

    //upload files to the server by posting to this url
    fastify.put('/upload/image', async(req, res) => {
        //log this = user has uploaded new picture
        let dir = "./server/data/img"
        let auth = req.headers.auth
        let title = req.headers.title
        let tags = req.headers.tags
        let description = req.headers.description
        var username
        console.log("Uploading a file to the server")
        let ID = crypto.randomBytes(10).toString('hex')
        filename = ID + path.extname(req.headers.name);
        const db = client.db('database')
        if(tags.length == 1 && a[0] == "")
            tags = null
        else
            tags = tags.substring(1, tags.length-1).replace(/"/g,'').split(",")
        if(description.length == 1 && description[0])
            description = null
        var cursor = await db.collection('accounts').findOne({token: auth})
        var obj = {id: ID, file: filename, title:title, description:description, author:cursor.username, tags:tags}
        var insert = await db.collection('images').insertOne(createImage(obj))
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
        //log this: user has changed their profile picture
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
                const db = client.db('database')
                console.log(`File stored to ${dir}/${filename}`)
                var cursor = db.collection('accounts').updateOne({username: user}, {$set: {profilePic: link}})   
                res.send({response: link}) //respond with updated image link! Don't need to, normal OK is fine now
            }
          }
        )
    })

    fastify.post('/accounts/q', async(req, res) => {
        let query = req.body.query 
        const db = client.db('database')
        var cursor = await db.collection('accounts').find({"username": {$regex: query, $options: 'i'}}).sort().toArray()
        let output = cursor.map(({_id, secretKey, registeredAt, password, token, email, verifCode, bio, firstName, surname, facebook, twitter, github, occupation, age, twoFactor, history, ...rest}) => rest)
        let obj = new Object()
        obj.total = await db.collection('accounts').countDocuments({"username": {$regex: query, $options: 'i'}})
        obj.users = output
        res.send(obj)
    })

    fastify.post('/accounts/query', async(req, res) => {
        let query = req.body.query 
        let page = req.body.page
        let pageSize = 25
        let offset = pageSize * (page - 1)
        const db = client.db('database')
        var cursor = await db.collection('accounts').find({"username": {$regex: query, $options: 'i'}}).sort().skip(offset).limit(pageSize).toArray()
        let output = cursor.map(({_id, secretKey, registeredAt, password, token, email, verifCode, bio, firstName, surname, facebook, twitter, github, occupation, age, twoFactor, history, ...rest}) => rest)
        let obj = new Object()
        obj.total = await db.collection('accounts').countDocuments({"username": {$regex: query, $options: 'i'}})
        obj.users = output
        res.send(obj)
    })

    fastify.post('/images/q', async (req, res) => { 
        //somehow need to send back the total number of pages so I can map the buttons
        const db = client.db('database')
        let query = req.body.query
        var cursor = await db.collection('images').find({"title": {$regex: query, $options: 'i'}}).toArray()
        let output = cursor.map(({_id, description, tags, comments, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        let obj = new Object()
        obj.total = await db.collection('images').countDocuments()
        obj.images = output
        res.send(obj)
    })
    
    fastify.post('/images/get', async (req, res) => { 
        //somehow need to send back the total number of pages so I can map the buttons
        const db = client.db('database')
        let page = req.body.page
        let pageSize = 9
        let offset = pageSize * (page - 1)
        delete req.body.page
        var cursor = await db.collection('images').find().sort(req.body).skip(offset).limit(pageSize).toArray()
        let output = cursor.map(({_id, description, tags, comments, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
            //key["count"] = count
        })
        let obj = new Object()
        obj.total = await db.collection('images').countDocuments()
        obj.images = output
        res.send(obj)
    })

    fastify.post('/images/id', async (req, res) => {  //image database
        let id = req.body.id
        const db = client.db('database')
        var views = await db.collection('images').updateOne({id: id}, {$inc:{views: 1}})
        var cursor = await db.collection('images').findOne({id: id})
        delete cursor._id
        cursor.file = "http://localhost:3000/img/" + cursor.file
        res.send(cursor)
    })

    fastify.patch('/images/rate', async (req, res) => {
        //log this: user has rated an image
        let id = req.body.id
        let method = req.body.method
        const db = client.db('database')
        if (method == 1){
            var cursor = await db.collection('images').updateOne({id: id}, {$inc:{points: 1}})
        }
        else if (method == -1){
            var cursor = await db.collection('images').updateOne({id: id}, {$inc:{points: -1}})
        }
        else
            res.code(400).send(new Error("Invalid operation"))
        res.code(200).send()
    })

    fastify.post('/comment/add', async (req, res) => { 
        //log this: user has added new comment
        let content = req.body.content
        let username = req.body.username
        let id = req.body.id
        const db = client.db('database')
        let avatar = await db.collection('accounts').findOne({username:username})
        avatar = avatar.profilePic
        var cursor = await db.collection('comments').insertOne({content: content, username: username, imageID: id, uploaded: new Date(), points: 0, avatar: avatar})
        res.code(200).send()
    })

    fastify.post('/comment/get', async (req, res) => {
        let id = req.body.id
        const db = client.db('database')
        var cursor = await db.collection('comments').find({imageID: id}).toArray()
        res.send(cursor)
    })

    fastify.patch('/comment/edit', async (req, res) => {

    })

    fastify.delete('/comment/delete', async (req, res) => {

    })

    fastify.get('/carousel/get', async (req, res) => {


    })
}

module.exports = routes