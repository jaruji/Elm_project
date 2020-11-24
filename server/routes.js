const fs = require('fs');
const {pipeline} = require("stream");
const path = require('path');
const nodemailer = require('nodemailer');
const ObjectId = require('mongodb').ObjectID
const MongoClient = require('mongodb').MongoClient
const assert = require('assert')
const gpc = require('generate-pincode')
const crypto = require('crypto')

//name of MongoDB database that should be used (will contain all the collections)
const database = 'database'

//database url and connection on server start
const url = 'mongodb://localhost:27017';
const client = new MongoClient(url, {useNewUrlParser:true, useUnifiedTopology:true})
const connection = client.connect()

//function that receives an account object and adds more values (will be stored in db)
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

//receives image obj and adds more data before storing in db
function createImage(obj){
    obj.points = 0
    obj.views = 0
    obj.favorites = 0
    obj.uploaded = new Date()
    return obj
}


//send activation code to receiver by using nodemailer module
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
        } 
        else {
            console.log('Email sent: ' + info.response);
        }
    });
}

//function that returns number of days for a selected month (in selected year)
function daysInMonth(month,year) {
    return new Date(year, month, 0).getDate();
};

//function routes contains all endpoints, which are necessary for communication with
//our client application
async function routes(fastify) {

    //endpoint registers an account if username and email are unique, otherwise returns 400 error code
    fastify.post('/account/sign_up', async (req, res) => {    
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db(database)
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

    //used for validating log in creditentials (if username/email are unique)
    //used for dynamic checking (sending HTTP request from client on every onInput event)
    fastify.post('/account/validate', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db(database)
        var cursor = await db.collection('accounts').find(req.body).toArray(function(err, docs){
            if(docs.length === 0)
                res.send({response: "Error"})
            else
                res.send({response: "OK"})
        })
    })

    //tell server you want to receive an e-mail containg a verification code to verify your e-mail address
    fastify.get('/mailer/send', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        let code = gpc(6) //generate the 6-digit verification code
        let email = req.query.mail
        const db = client.db(database)
        var cursor = await db.collection('accounts').updateOne({email: email}, {$set: {verifCode: code}})
        client.close()
        sendActivationMail(email, code)
        res.code(200).send()
    })

    //endpoint used to verify your email address (find acc based on auth header and compoare)
    //the verification codes - if equal, verify the account by {response: true} response
    fastify.get('/account/verify', async(req, res) => {
        //log this: user has verified his account
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db(database)
        let auth = req.headers.auth
        let username = req.query.username
        let code = req.query.code
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

    //endpoint used for singing into your account by entering your username and password
    fastify.post('/account/sign_in', async(req, res) => {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "X-Requested-With")
        const db = client.db(database)
        let username = req.body.username
        let password = req.body.password
        var cursor = await db.collection('accounts').findOne({username: username, password: password}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                //delete all sensitive info that is not needed inside the web application
                delete result._id
                delete result.password
                delete result.verifCode
                delete result.secretKey
                delete result.twoFactor
                //generate new session token for every new login
                let token = crypto.randomBytes(48).toString('hex')
                var update = await db.collection('accounts').updateOne({username: username, password: password}, {$set: {token: token}}, function(err, answer){
                    if(err){
                        res.code(500).send(new Error("Server error"))
                    }
                    else if(answer){
                        result.token = token
                        res.send(result)
                    }
                    else
                        res.code(400).send()
                })
            }
            else{   
                res.code(400).send(new Error("Invalid creditentials"))             
            }
        })
    })

    //authenticate user based on his token only, return account info (same as sign_in)
    fastify.get('/account/auth', async(req, res) => {
        let auth = req.headers.auth
        const db = client.db(database)
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

    //endpoint used for changing your password, requires auth header to authenticate the user
    //account is found based on token value
    fastify.patch('/account/password', async(req, res) => {
        const db = client.db(database)
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

    //endpoint for deleting user account, requires auth header and password to prove user identity
    fastify.delete('/account/delete', async(req, res) => {
        const db = client.db(database)
        let auth = req.headers.auth
        let password = req.body.password
        var user = await db.collection('accounts').findOne({token: auth, password: password}, async function(err, result) {
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            if (result){
                //delete all information related to the account (because username is used instead of FK)
                //if we don't delete everything and a new account is created with the same username
                //it will cause conflicts
                await db.collection('accounts').deleteMany({token: auth, username: result.username})
                await db.collection('images').deleteMany({author: result.username})
                await db.collection('comments').deleteMany({username: result.username})
                await db.collection('votes').deleteMany({username: result.username})
                await db.collection('favorites').deleteMany({username: result.username})
                res.code(200).send()
            } 
            else{
                res.code(400).send(new Error("Invalid creditentials"))
            }
        })

    })

    //return only public user info! Used while displaying user profile (receives username)
    fastify.get('/account/user', async(req, res) => {
        let username = req.query.username
        const db = client.db(database)
        var cursor = await db.collection('accounts').findOne({username: username}, function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                //delete all sensitive information
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

    //get posts belonging to a certain account, for performance reasons added limit option,
    //which allows to manage the number of posts received
    //if limit value is 0, return all posts! (0 means no limit)
    fastify.get('/account/posts', async(req, res) => {
        //get preview of user's posts
        let author = req.query.username
        let limit = req.query.limit
        const db = client.db(database)
        var cursor = await db.collection('images').find({author: author}).sort({uploaded: -1}).limit(parseInt(limit)).toArray()
        let output = cursor.map(({_id, description, tags, comments, upvotes, downvotes, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        res.send(output)
    });

    //return 5 latest posts, which are displayed on homepage of our application
    fastify.get('/posts/latest', async(req, res) => {
        //get preview of user's posts
        const db = client.db(database)
        var cursor = await db.collection('images').find().sort({uploaded: -1}).limit(5).toArray()
        let output = cursor.map(({_id, description, tags, comments, upvotes, downvotes, ...rest}) => rest)
        //only filenames are stored, so we need to add URL
        //if port of server is changed, this needs to change too!
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        res.send(output)
    });

    //simple update of basic profile information 
    fastify.patch('/account/update', async(req, res) => {
        //log this = user has updating his personal settings
        let auth = req.headers.auth
        let bio = req.body.bio
        let facebook = req.body.facebook
        let twitter = req.body.twitter
        let github = req.body.github
        const db = client.db(database)
        //if url is deleted in webapp (means we receive ""), delete it in database too
        if(facebook === "")
            facebook = null
        if(twitter === "")
            twitter = null
        if(github === "")
            github = null
        let cursor = db.collection('accounts').updateMany({token: auth}, {$set:{bio: bio, facebook:facebook, twitter:twitter, github:github, updatedAt: new Date()}})
        res.code(200).send()
    });

    //get account activity for a certain month, return object with number of posts for each day of month
    fastify.get('/account/activity', async(req, res) => {
        let date = req.query.date
        let username = req.query.username
        const db = client.db(database)
        let cursor = 
        //retrieve year, month and day of month from timestamp "uploaded" in database
        db.collection('images').aggregate([
            {$match:
            {
                author: username
            }},
            {$project:
            {
                year: { $year: "$uploaded" },
                month: { $month: "$uploaded" },
                day: { $dayOfMonth: "$uploaded" }
            }}
        ]).toArray(function(err, results){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(results){
                //for every day of month, count the number of posts and construct an array
                //which contains these values. This array will be sent as a response to this request.
                let output = []
                for(let i = 1; i < daysInMonth(date, 2020) + 1; i++){
                    output.push({day: i, count: 0})
                }
                results.forEach(key => {
                    if(key.month == date){
                        output[key.day - 1].count++
                    }
                })
                res.send(output)
            }
            else{
                res.code(400).send(new Error("Bad request"))
            }
        })
    })

    //upload metadata to a image based to its ID. Multipart body was not working, so this was
    //the only other solution I came up with. It is possible for the server to crash during posting
    //metadata, which would result in a faulty image stored in database (image without metadata) - should be fixed in the future
    fastify.post('/upload/metadata', async(req, res) => {
        let auth = req.headers.auth
        let id = req.body.id
        let title = req.body.title
        let tags = req.body.tags
        if(tags.length === 0)
            tags = null
        let description = req.body.description
        const db = client.db(database)
        var cursor = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(result){
                await db.collection('images').updateOne({id: id}, {$set:{title: title, tags: tags, description: description, author: result.username}}, async function(err, result){
                    if(err){
                        res.code(500).send(new Error("Server error"))
                        await db.collection('images').findOne({id: id}, function(err, result){
                            if(result){
                                //clean up
                                fs.unlinkSync("../server/data/img/" + result.file)
                            }
                        })
                    }
                    else if(result){
                        res.code(200).send()
                    }
                    else{
                        res.code(400).send(new Error("No image with this ID"))
                    }
                }) 
            }
            else{
                res.code(401).send(new Error("Not authorized"))
            }
        })
    })

    //upload files to the server by posting to this url. If image fails to store on server side
    //unsync (delete image) and respond with code 400. Otherwise return the ID of uploaded image
    //so in the next step, it's metadata can be uploaded with this ID as it's parameter.
    fastify.put('/upload/image', async(req, res) => {
        //log this = user has uploaded new picture
        let dir = "../server/data/img"
        let auth = req.headers.auth
        console.log("Uploading a file to the server")
        let ID = crypto.randomBytes(10).toString('hex')
        filename = ID + path.extname(req.headers.name);
        const db = client.db(database)
        var cursor = await db.collection('accounts').findOne({token: auth})
        var obj = {id: ID, file: filename, author:cursor.username}
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
                res.send({response: ID})    //respond with ID if upload succeeded
            }
          }
        )
    })

    //upload profile image, very simillar to /upload/image
    fastify.put('/upload/profile', async(req, res) => {
        user = req.headers["user"];
        const db = client.db(database)
        await db.collection('accounts').findOne({username: user}, function(err, result){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(result){
                //name profilepic based on objectID of account so no issues can arise from
                //accounts with weird names, that could possibly cause problems or even crash the server
                let filename = result._id.toHexString() + path.extname(req.headers["name"]);    //get name of received file
                let link = "http://localhost:3000/img/profile/" + filename
                let dir = "../server/data/img/profile/"
                if(result.profilePic != null){
                    let oldAvatar = result.profilePic.split('/').pop()
                    fs.unlinkSync("./server/data/img/profile/" + oldAvatar)
                }
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
                        var cursor = db.collection('accounts').updateOne({username: user}, {$set: {profilePic: link}})   
                        res.code(200).send()
                    }
                  }
                )
            }
            else{
                res.code(400).send(new Error("No user with this username"))
            }
        })
    })

    //seach accounts based on their username (if username contains q, account is eligible)
    fastify.get('/accounts/search', async(req, res) => {
        let query = req.query.q
        const db = client.db(database)
        var cursor = await db.collection('accounts').find({"username": {$regex: query, $options: 'i'}}).sort().toArray()
        //leave sensitive/not necessary info out
        let output = cursor.map(({_id, secretKey, registeredAt, password, token, email, verifCode, bio, firstName, surname, facebook, twitter, github, occupation, age, twoFactor, history, ...rest}) => rest)
        let obj = new Object()
        obj.total = await db.collection('accounts').countDocuments({"username": {$regex: query, $options: 'i'}})
        obj.users = output
        res.send(obj)
    })

    //return accounts matching the query and use pagination to load only a certain ammount of accounts at a time
    //pagesize is 20, meaning that one page will show and receive only 20 accounts at max
    //next page will show indexes 20-40 and so on
    fastify.get('/accounts/paginate', async(req, res) => {
        let query = req.query.q 
        let page = parseInt(req.query.page)
        let pageSize = 20
        //calculate offset so we can retrieve the next 20 images if page > 1
        let offset = pageSize * (page - 1)
        const db = client.db(database)
        //the search is case insensitive
        var cursor = await db.collection('accounts').find({"username": {$regex: query, $options: 'i'}}).sort().skip(offset).limit(pageSize).toArray()
        //leave out sensitive/unnecessary information
        let output = cursor.map(({_id, secretKey, registeredAt, password, token, email, verifCode, bio, firstName, surname, facebook, twitter, github, occupation, age, twoFactor, history, ...rest}) => rest)
        let obj = new Object()
        //count number of matches, which is needed for pagination on web app side!
        obj.total = await db.collection('accounts').countDocuments({"username": {$regex: query, $options: 'i'}})
        obj.users = output
        res.send(obj)
    })

    //retrieve all images which were favorited by the user in the past
    //receives username and returns all favorites
    fastify.get('/account/favorites', async(req, res) =>{
        let username = req.query.username
        const db = client.db(database)
        var cursor = await db.collection('favorites').find({username: username}).toArray(async function(err, results){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(results){
                if(results.length === 0)
                    res.send(results)
                let output = []
                for(let i = 0; i < results.length; i++){
                    var user = await db.collection('images').findOne({id: results[i].id}, function(err, result){
                        if(err){
                            res.code(500).send()
                        }
                        else if(result){
                            result["uploaded"] = results[i].date
                            output.push(result)
                            if(i === results.length - 1){
                                //again, we need to complete the URL because only filename is stored
                                output.map(function(key){
                                    key["file"] = "http://localhost:3000/img/" + key.file
                                })
                                res.send(output)
                            }
                        }
                        else{
                            res.code(400).send()
                        }
                    })
                }
            }
            else{
                res.code(400).send()
            }
        })
    })

    //simple search, return images that match the query (if title contains q) 
    fastify.get('/images/search', async (req, res) => { 
        const db = client.db(database)
        let query = req.query.q
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
    
    //get all images but with pagination, so only a fixed amount at a time (max 9 images per page)
    fastify.get('/images/get', async (req, res) => { 
        const db = client.db(database)
        let page = parseInt(req.query.page)
        //obtain a parameter by which the images will be sorted
        let sort = req.query.sort
        //obtain order of sorting
        let order = parseInt(req.query.order)
        let query = {}
        query[sort] = order
        let pageSize = 9
        let offset = pageSize * (page - 1)
        //find images based on current page, but before that we need to sort the collection
        var cursor = await db.collection('images').find().sort(query).skip(offset).limit(pageSize).toArray()
        let output = cursor.map(({_id, description, tags, comments, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
            //key["count"] = count
        })
        let obj = new Object()
        //again, total count of images is needed for pagination on frontend side
        obj.total = await db.collection('images').countDocuments()
        obj.images = output
        res.send(obj)
    })

    //get a specific image based on its ID. Is used with post page, loads all information about
    //the image. Also updates viewcount, so with every new request we raise the view value by 1
    fastify.get('/image', async (req, res) => {  //image database
        const db = client.db(database)
        let id = req.query.id
        var views = await db.collection('images').updateOne({id: id}, {$inc:{views: 1}})
        var cursor = await db.collection('images').findOne({id: id})
        delete cursor._id
        cursor.file = "http://localhost:3000/img/" + cursor.file
        res.send(cursor)
    })

    //get the stats of specific image - views, votes, favorites so we can display them without
    //requesting the entire image
    fastify.get('/image/stats', async (req, res) => {
        const db = client.db(database)
        let id = req.query.id
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

    //endpoint which informs a user about his interactions with specific image -
    //meaning that database need to keep track of if the user voted on a specific image or
    //if he favorited it - if we didn't track this, one user would be able to vote/favorite an image
    //multiple times, which doesn't make sense
    fastify.get('/image/info', async (req, res) => {
        const db = client.db(database)
        let id = req.query.id
        let auth = req.headers.auth
        var user = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(result){
                var fav = await db.collection('favorites').findOne({id:id, username: result.username})
                if(fav === null)
                    fav = false
                else
                    fav = true
                var cursor = await db.collection('votes').findOne({id: id, username: result.username}, function(err, result){
                    if(err){
                        res.code(500).send()
                    }
                    else if(result){
                        res.send({vote: result.vote, favorite: fav})
                    }
                    else{
                        res.send({vote: "none", favorite: fav})
                    }
                })
            }
            else{
                res.send({vote: "invalid", favorite: false})
            }
        })
    })


    //image rating, there are 3 basic types of votes - upvote (+1 point), downvote (-1)
    //and veto, meaning the user wants to take back his vote. Only logged in users can vote!
    fastify.post('/image/rate', async (req, res) => {
        //log this: user has rated an image
        let auth = req.headers.auth
        let id = req.body.id
        let vote = req.body.vote
        const db = client.db(database)
        var cursor = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Something went wrong on the server's side"))
            }
            else if(result){
                let username = result.username
                //handle case if vote is upvote
                if (vote === "upvote"){
                    var upvote = await db.collection('images').updateOne({id: id}, {$inc:{points: 1}})
                    var insert = await db.collection('votes').updateOne({id: id, username: username}, {$set:{id: id, username: username, vote: vote }}, {upsert: true})
                }
                //if vote is downvote
                else if (vote === "downvote"){
                    var downvote = await db.collection('images').updateOne({id: id}, {$inc:{points: -1}})
                    var insert = await db.collection('votes').updateOne({id: id, username: username}, {$set:{id: id, username: username, vote: vote }}, {upsert: true})
                }
                //if we want to take back our initial vote
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
    
    //image favorite is simpler than rating - only favorite/unfavorite
    //if we unfavorite, delete the entry from favorites collection
    //only logged in users can favorite an image
    fastify.post('/image/favorite', async(req, res) => {
        let id = req.body.id
        let auth = req.headers.auth
        const db = client.db(database)
        var cursor = await db.collection('accounts').findOne({token: auth}, async function(err, result){
            if(err){
                res.code(500).send(new Error("Server error"))
            }
            else if(result){
                var fav = await db.collection('favorites').findOne({username: result.username, id: id}, async function(err, answer){
                    if(err){
                        res.code(500).send(new Error("Server error"))    
                    }
                    else if(answer){
                        await db.collection('images').updateOne({id: id}, {$inc:{favorites: -1}})
                        await db.collection('favorites').deleteOne({username: result.username, id:id})
                        res.code(200).send()
                    }
                    else{
                        await db.collection('images').updateOne({id: id}, {$inc:{favorites: 1}})
                        await db.collection('favorites').insertOne({username: result.username, id: id, date: new Date()})
                        res.code(200).send()
                    }
                })
            }
            else{
                res.code(400).send(new Error("Not authorized"))
            }
        })
    })

    //deleting an image requires a logged in user and ID of image we want to delete 
    fastify.delete('/image/delete', async(req, res) =>{
        let id = req.body.id
        let auth = req.headers.auth
        const db = client.db(database)
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
                        //delete the image from our fs so it won't be left hanging
                        fs.unlink("./server/data/img/" + result.file, async function(err){
                            if(err){
                                res.code(500).send(new Error("File deletion failed"))
                            }
                            else{
                                //delete all info connected to the image
                                await db.collection('images').deleteOne({id: id})
                                await db.collection('comments').deleteMany({imageID: id})
                                await db.collection('votes').deleteMany({id: id})
                                await db.collection('favorites').deleteMany({id: id})
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

    //add a new comment, very simple - just receive content and id of image
    //also needs username of author, so we can use it later to select profile image from
    //accounts collection
    fastify.post('/comment/add', async (req, res) => { 
        //log this: user has added new comment
        let content = req.body.content
        let username = req.body.username
        let id = req.body.id
        const db = client.db(database)
        var cursor = await db.collection('comments').insertOne({content: content, username: username, imageID: id, uploaded: new Date(), points: 0 })
        res.code(200).send()
    })

    //get all comments related to specific image based on image ID
    fastify.get('/comment/get', async (req, res) => {
        let id = req.query.id
        const db = client.db(database)
        var cursor = await db.collection('comments').find({imageID: id}).toArray( async function(err, results){
            if(err){
                res.code(500).send()
            }
            else if(results){
                if(results.length === 0)
                    res.send(results)
                //iterate over all comments and add a image loaded from accounts collection
                //this approach is better than storing the image together with comments, because
                //it would cause issues if the user would change his profile image to a file with
                //different file extension (because old profile images are deleted!)
                for(let i = 0; i < results.length; i++){
                    var user = await db.collection('accounts').findOne({username: results[i].username}, async function(err, result){
                        if(err){
                            res.code(500).send()
                        }
                        else if(result){
                            if(result.profilePic == null){
                                result.profilePic = "http://localhost:3000/img/profile/default.jpg"
                            }
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

    //allow user to edit the content of his comment
    //add edited timestamp (or updates if already added)
    //this timestamp will begin showing on comment in web app if it exists!
    fastify.patch('/comment/edit', async (req, res) => {
        let content = req.body.comment
        let id = req.body.id
        const db = client.db(database)
        var cursor = await db.collection('comments').updateOne({_id: ObjectId(id)}, {$set:{content: content, edited: new Date()}})
        res.code(200).send()
    })

    //simple comment deletion based on the ID of comment
    fastify.delete('/comment/delete', async (req, res) => {
        let id = req.body.id
        const db = client.db(database)
        var cursor = await db.collection('comments').deleteOne({_id: ObjectId(id)})
        res.code(200).send()
    })

    //used in dynamic search of tags - search is case insensitive, but only a full match
    //counts - meaning even if the query (q) is a substring, it still won't match
    //the output is paginated again
    fastify.get('/tags', async(req, res) => {
        let query = req.query.q
        let page = parseInt(req.query.page)
        let pageSize = 9
        let offset = pageSize * (page - 1) 
        const db = client.db(database)
        //if tag is composed of multiple words, this RegExp will find a match if q is one of these words
        //also it makes the search case insensitive (i)
        query = new RegExp(`\\b${query}\\b`, 'i')
        var cursor = await db.collection('images').find({tags: { $in: [query] }}).skip(offset).limit(pageSize).toArray()
        let output = cursor.map(({_id, description, tags, comments, ...rest}) => rest)
        output.map(function(key){
            key["file"] = "http://localhost:3000/img/" + key.file
        })
        let obj = new Object()
        //needed for pagination...
        obj.total = await db.collection('images').countDocuments({tags: { $in: [query] }})
        obj.images = output
        res.send(obj)
    })

    //returns (unique) tags of the last 10 uploaded images
    //could not figure out how to return most frequent tags, so I made it simpler
    fastify.get('/tags/trending', async(req, res) => {
        const db = client.db(database)
        var cursor = db.collection('images').find().sort({uploaded: -1}).limit(10).toArray(function(err, results){
            if(err){
                res.code(500).send()
            }
            else if(results){
                //return only unique tags
                var arr = []
                results.forEach(key =>{
                    if(key.tags === null || key.tags === undefined)
                        return
                    key.tags.forEach(tag =>{
                        if(arr.includes(tag)){
                        }
                        else
                            arr.push(tag)
                    })
                })
                res.send(arr)
            }
            else{
                res.code(400).send()
            }
        })
    })
}

module.exports = routes