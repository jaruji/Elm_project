//imports
const fastify = require('fastify')()
const path = require('path')
const fs = require('fs');


//routers

fastify.register(require('./routes'), { prefix: '' })
fastify.register(require('fastify-multipart'))

//enables CORS
fastify.register(require('fastify-cors'), {
   origin: "*",
   allowedHeaders: ['Origin', 'X-Requested-With', 'Accept', 'Content-Type', 'Authorization', 'name', 'user'],
   methods: ['GET', 'PUT', 'PATCH', 'POST', 'DELETE']
})

//allows serving static image files from url
fastify.register(require('fastify-static'), {
  root: path.join(__dirname, 'data/img'),
  prefix: '/img', // optional: default '/'
})

//allows accepting of file uploads to server
fastify.addContentTypeParser('*', function (req, done) {
  done(null, req)
})

//listener
//let obj = fs.readFileSync('accounts.json')
//console.log(obj)
//let dict = JSON.parse(obj);
//console.log(dict.password)
fastify.listen(3000, (err) => {
    if (err) {
        console.log(err)
        process.exit(1)
    } else {
        console.log('Server is up on port 3000...')
    }

})
