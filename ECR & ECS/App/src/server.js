const express = require('express');
const app = express();

app.use(function(req, res, next) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
    next();
});

// Hard-Coded for demo
const CONTACTS = [
                    {
                      "name": "hammed akinwale",
                      "email": "hammeda@test.com",
                      "cell": "748-848-939"
                    },
                    {
                      "name": "solomon onwoansonya",
                      "email": "solomon@test.com",
                      "cell": "098-345-903"
                    },
                    {
                      "name": "peter mark",
                      "email": "peter@test.com",
                      "cell": "609-956-234"
                    }
                ];

app.get('/contacts', (req, res) => {
  res.json({contacts: CONTACTS});
});

app.listen(3000, () =>{
   console.log('Server running on port 3000.'); 
});
