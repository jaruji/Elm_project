//imports
const fastify = require('fastify')()
const path = require('path')

//routers

fastify.register(require('./routes'), { prefix: '' })

//listener
fastify.listen(3000, (err) => {
    if (err) {
        console.log(err)
        process.exit(1)
    } else {
        console.log('Server is up on port 3000...')
    }

})
