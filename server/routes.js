const fs = require('fs');
const {pipeline} = require("stream");
const path = require('path');
const nodemailer = require('nodemailer');
const ObjectId = require('mongodb').ObjectID
const MongoClient = require('mongodb').MongoClient
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
    obj.facebook = null
    obj.twitter = null
    obj.github = null
    obj.registeredAt = new Date()
    obj.twoFactor = false
    obj.secretKey = null
    obj.token = crypto.randomBytes(48).toString('hex')
    return obj
}

function createImage(obj){
    obj.points = 0
    obj.views = 0
    obj.favorites = 0
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
        let email = req.body.email
        let username = req.body.username
        let cursor = db.collection('accounts').findOne({ $or: [ { email: email }, { username: username } ] }, async function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                res.code(400).send(new Error("E-mail address or username are already taken!"))
            }
            else{    
                let insert = db.collection('accounts').insertOne(createAccount(req.body))
                res.send({ response : "OK" })
            }
        })
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
        res.code(200).send()
    })

    fastify.post('/account/verify', async(req, res) => {
        //log this: user has verified his account
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db('database')
        let auth = req.headers.auth
        let username = req.body.username
        let code = req.body.verifCode
        var cursor = await db.collection('accounts').findOne({token: auth, username: username, verifCode: code}, async function(err, result){
            if(err){
                console.log(err)
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                var temp = await db.collection('accounts').updateOne({token: auth}, {$set: {verif: true, verifCode: null}})
                res.send({response: true})
            }
            else{
                res.send({response: false})
            }
        }) 
    })


    fastify.post('/account/sign_in', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db('database')
        var cursor = await db.collection('accounts').findOne(req.body, function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                delete result._id
                delete result.password
                delete result.verifCode
                delete result.secretKey
                delete result.twoFactor
                res.send(result)
            }
            else{   
                res.code(400).send(new Error("Invalid creditentials"))             
            }
        })
    })

    fastify.get('/account/auth', async(req, res) => {
        let auth = req.headers.auth
        const db = client.db('database')
        var cursor = await db.collection('accounts').findOne({token: auth}, function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                //hide properties that are not necessary/security risk!
                delete result._id
                delete result.password
                delete result.verifCode
                delete result.secretKey
                delete result.twoFactor
                res.send(result)
            }
            else{
                res.code(400).send(new Error("Invalid token"))
            }
        })
    })

    fastify.patch('/account/password', async(req, res) => {
        const db = client.db('database')
        let auth = req.headers.auth
        let oldPass = req.body.oldPassword
        let newPass = req.body.newPassword
        var test = await db.collection('accounts').findOne({token: auth, password: oldPass}, async function(err, result) {
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if (result){
                var cursor = await db.collection('accounts').updateOne({token: auth}, {$set:{password: newPass}})
                res.code(200).send()
            } 
            else{
                res.code(400).send(new Error("Invalid creditentials"))
            }
        })
    })

    fastify.delete('/account/delete', async(req, res) => {
        //maybe delete the images from system too?
        const db = client.db('database')
        let auth = req.headers.auth
        let password = req.body.password
        var user = await db.collection('accounts').findOne({token: auth, password: password}, async function(err, result) {
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            if (result){
                var delAcc = await db.collection('accounts').deleteMany({token: auth, username: result.username})
                var delImg = await db.collection('images').deleteMany({author: result.username})
                var delComm = await db.collection('comments').deleteMany({username: result.username})
                res.code(200).send()
            } 
            else{
                res.code(400).send(new Error("Invalid creditentials"))
            }
        })

    })

    fastify.post('/account/user', async(req, res) => {
        //return only public user info! input is username, returns
        let username = req.body.username
        const db = client.db('database')
        var cursor = await db.collection('accounts').findOne({username: username}, function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                delete result._id
                delete result.password
                delete result.verifCode
                delete result.email
                delete result.token
                delete result.twoFactor
                delete result.secretKey
                res.send(result)
            }
            else{
                res.code(400).send(new Error("This profile does not exist"))
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
        let facebook = req.body.facebook
        let twitter = req.body.twitter
        let github = req.body.github
        const db = client.db('database')
        let cursor = db.collection('accounts').updateMany({token: auth}, {$set:{bio: bio, facebook:facebook, twitter:twitter, github:github, updatedAt: new Date()}})
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
                res.send({response: ID})
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
                res.code(200).send()
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
        let pageSize = 20
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
        const db = client.db('database')
        let auth = req.headers.auth
        let id = req.body.id
        let username
        var views = await db.collection('images').updateOne({id: id}, {$inc:{views: 1}})
        var cursor = await db.collection('images').findOne({id: id})
        delete cursor._id
        cursor.file = "http://localhost:3000/img/" + cursor.file
        res.send(cursor)
    })

    fastify.post('/images/stats', async (req, res) => {
        const db = client.db('database')
        let id = req.body.id
        var cursor = await db.collection('images').findOne({id: id})
        delete cursor._id
        delete cursor.file
        delete cursor.id
        delete cursor.description
        delete cursor.author
        delete cursor.tags
        delete cursor.uploaded
        delete cursor.title
        res.send(cursor)
    })

    fastify.post('/images/getVote', async (req, res) => {
        const db = client.db('database')
        let id = req.body.id
        let auth = req.headers.auth
        var user = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send()
            }
            else if(result){
                var cursor = await db.collection('votes').findOne({id: id, username: result.username}, function(err, result){
                    if(err){
                        res.code(500).send()
                    }
                    else if(result){
                        res.send({vote: result.vote})
                    }
                    else{
                        res.send({vote: "none"})
                    }
                })
            }
            else{
                res.send({vote: "invalid"})
            }
        })
    })

    fastify.post('/images/rate', async (req, res) => {
        //log this: user has rated an image
        let auth = req.headers.auth
        let id = req.body.id
        let vote = req.body.vote
        const db = client.db('database')
        var cursor = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                let username = result.username
                if (vote === "upvote"){
                    var upvote = await db.collection('images').updateOne({id: id}, {$inc:{points: 1}})
                    var insert = await db.collection('votes').updateOne({id: id, username: username}, {$set:{id: id, username: username, vote: vote }}, {upsert: true})
                }
                else if (vote === "downvote"){
                    var downvote = await db.collection('images').updateOne({id: id}, {$inc:{points: -1}})
                    var insert = await db.collection('votes').updateOne({id: id, username: username}, {$set:{id: id, username: username, vote: vote }}, {upsert: true})
                }
                else if(vote === "veto"){
                    var find = await db.collection('votes').findOne({id: id, username: username}, async function(err, result){
                        if(err){
                            res.code(500).send(new Error("Something went wrong on the server's side")) 
                        }
                        else if(result){
                            if(result.vote == "upvote"){
                                var downvote = await db.collection('images').updateOne({id: id}, {$inc:{points: -1}})
                            }
                            else if(result.vote == "downvote"){
                                var upvote = await db.collection('images').updateOne({id: id}, {$inc:{points: 1}})
                            }
                            var del = await db.collection('votes').deleteOne({id: id, username: username})
                        }
                        else{
                            res.code(500).send(new Error("You have never rated this image"))
                        }
                    })
                }
                else
                    res.code(400).send(new Error("Invalid operation"))
                    }
                    else{
                        res.code(400).send(new Error("Unauthorized operation"))
                    }
                })
        res.code(200).send()
    })

    fastify.delete('/images/delete', async(req, res) =>{
        let id = req.body.id
        let auth = req.headers.auth
        const db = client.db('database')
        var cursor = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(result){
                var img = await db.collection('images').findOne({id: id}, async function(err, result){
                    if(err){
                        res.code(500).send(new Error("Server error"))
                    }
                    else if(result){
                        fs.unlink("./server/data/img/" + result.file, async function(err){
                            if(err){
                                res.code(500).send(new Error("File deletion failed"))
                            }
                            else{
                                var del = await db.collection('images').deleteOne({id: id})
                                del = await db.collection('comments').deleteMany({imageID: id})
                                del = await db.collection('votes').deleteMany({id: id})
                                res.code(200).send()
                            }
                        })
                    }
                    else{
                        res.code(400).send(new Error("No image with this ID")) 
                    }
                })
            }
            else{
                res.code(400).send(new Error("You are not authorized for this action"))
            }
        })
    })

    fastify.post('/comment/add', async (req, res) => { 
        //log this: user has added new comment
        let content = req.body.content
        let username = req.body.username
        let id = req.body.id
        const db = client.db('database')
        var cursor = await db.collection('comments').insertOne({content: content, username: username, imageID: id, uploaded: new Date(), points: 0 })
        res.code(200).send()
    })

    fastify.post('/comment/get', async (req, res) => {
        let id = req.body.id
        const db = client.db('database')
        var cursor = await db.collection('comments').find({imageID: id}).toArray( async function(err, results){
            if(err){
                res.code(500).send()
            }
            else if(results){
                if(results.length === 0)
                    res.send(results)
                for(let i = 0; i < results.length; i++){
                    var user = await db.collection('accounts').findOne({username: results[i].username}, function(err, result){
                        if(err){
                            res.code(500).send()
                        }
                        else if(result){
                            results[i].avatar = result.profilePic
                            if(i === results.length - 1)
                                res.send(results)
                        }
                        else{
                            res.code(400).send()
                        }
                    })
                }
            }
            else{
                res.code(400).send(new Error("Image with this ID does not exist"))
            }
        })
    })

    fastify.patch('/comment/edit', async (req, res) => {
        let content = req.body.content
        let id = req.body.id
        const db = client.db('database')
        var cursor = await db.collection('comments').updateOne({_id: ObjectId(id)}, {$set:{content: content}})
        res.code(200).send()
    })

    fastify.delete('/comment/delete', async (req, res) => {
        let id = req.body.id
        const db = client.db('database')
        var cursor = await db.collection('comments').deleteOne({_id: ObjectId(id)})
        res.code(200).send()
    })

    fastify.get('/carousel/get', async (req, res) => {


    })

    fastify.post('/tags/query', async(req, res) => {
        let query = req.body.query
        let page = req.body.page
        let pageSize = 9
        let offset = pageSize * (page - 1) 
        const db = client.db('database')
        query = new RegExp(`\\b${query}\\b`, 'i')
        var cursor = await db.collection('images').find({tags: { $in: [query] }}).skip(offset).limit(pageSize).toArray()
        let output = cursor.map(({_id, description, tags, comments, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        let obj = new Object()
        obj.total = await db.collection('images').countDocuments({tags: { $in: [query] }})
        obj.images = output
        res.send(obj)
    })
}

module.exports = routes