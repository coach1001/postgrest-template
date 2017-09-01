var express = require('express');
var cors = require('cors');
var app = express();
var storage = require('filestorage').create();
var multiparty = require('connect-multiparty');
var multipartyMiddleware = multiparty();
var nocache = require('nocache');
const CONFIG = require('./config.json');

var fs = require('fs');

app.use(cors());
app.use(nocache());

app.get('/', function (req, res) {
  res.send('File API!');
});

app.post('/api/file', multipartyMiddleware, function(req, res) {
  console.log(req.headers)
  res.status(200).json({message: 'OKAY'});
  /*storage.insert(req.files.file.originalFilename, req.files.file.path , function(err,id,stat){
    fs.unlink(req.files.file.path, function(err){
        if(err){
          res.status(500).json({fileId: null, message: 'File Creation Failed'})
        }else{
          res.status(200).json({fileId: id, message: 'File Creation Succeeded'});
        }
    });
	});*/
});

app.patch('/api/file?:fileId', multipartyMiddleware, function(req, res) {
	var fileId = req.query.fileId;
	storage.update(fileId, req.files.file.originalFilename, req.files.file.path , function(err,id,stat){
		fs.unlink(req.files.file.path, function(err){
        if(err){
          res.status(500).json({fileId: id, message: 'File Updating Failed'})
        }else{
          res.status(200).json({fileId: id, message: 'File Updating Succeeded'});
        }
    });
	});
});

app.delete('/api/file?:fileId',function(req,res){
  var fileId = req.query.fileId;
  storage.remove(fileId, function(err){
    if(err){
      res.status(500).json({fileId: id, message: 'File Deletion Failed'})
    } else {
      res.status(200).json({fileId: id, message: 'File Deletion Succeeded'})
    }
  });
});

app.get('/api/list',function(req,res){
	storage.listing(function(err,arr){
    if(err){
      res.status(500).json({files: null, message: 'File List Retrieval Failed'})
    } else {
      res.status(200).json({files: arr, message: 'File List Retrieval Succeeded'});
    }

	});
});

app.get('/api/file?:fileId',function(req,res){
	storage.stat(fileId, function(err, stat) {
    if(err){
      res.status(500).json({message: 'File Retrieval Failed'});
    }else{
      res.status(200);
      res.set('Content-Disposition', stat.name);
    	res.set('Content-Length', stat.length);
    	res.set('Content-Type', stat.type);
    	res.set('Access-Control-Expose-Headers','Content-Disposition,Content-Length,Content-Type');
  		storage.pipe(2,req,res)
    }
	});
});

app.listen(CONFIG.SERVER_PORT, function () {
  console.log('File Storage Running on port 3005!');
});
