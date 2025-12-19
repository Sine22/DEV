const express = require('express')
const app = express()
const port = 4444

function Sample(host) {
  return { name: "Hello", description: "World", url: host }
}

app.get('/', (req, res) => {
  res.json(Sample(req.headers.host))
})

const server = app.listen(port, () => {
  console.log(`Listening on port ${port}`)
})

process.on('SIGINT', () => {
  server.close(() => console.log('Stopped'))
})

module.exports = { Sample, server }
