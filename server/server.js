const fastify = require('fastify')()
const path = require('path')

fastify.register(require('./routes'), { prefix: '' })

//handle multipart requests
fastify.register(require('fastify-multipart'))

//enables CORS
fastify.register(require('fastify-cors'), {
   origin: "*",
   allowedHeaders: ['Origin', 'X-Requested-With', 'Accept', 'Content-Type', 'Authorization', 'Content-Disposition'
   , 'name', 'user', 'auth' ],
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

fastify.listen(3000, (err) => {
    if (err) {
        console.log(err)
        process.exit(1)
    } else {
        console.log('Server is up on port 3000...')
    }

})
