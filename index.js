var express = require('express');
var cors = require('cors');
var app = express();
var storage = require('filestorage').create();
var multiparty = require('connect-multiparty');
var multipartyMiddleware = multiparty();
var nocache = require('nocache');
const CONFIG = require('./config.json');
var request = require('request');

var fs = require('fs');

app.use(cors());
app.use(nocache());

app.get('/', function (req, res) {
  res.send('File API!');
});

const createFileRequest = {
  url: CONFIG.POSTGREST.BASE_URL+'/'+CONFIG.POSTGREST.FILE.TABLE,
  method: 'POST',
  headers: {}
}
const updateFileRequest = {
  url: CONFIG.POSTGREST.BASE_URL+'/'+CONFIG.POSTGREST.FILE.TABLE,
  method: 'PATCH',
  headers: {}
}
const deleteFileRequest = {
  url: CONFIG.POSTGREST.BASE_URL+'/'+CONFIG.POSTGREST.FILE.TABLE,
  method: 'DELETE',
  headers: {}
}

app.post('/api/file', multipartyMiddleware, function(req_, res_) {

  storage.insert(req_.files.file.originalFilename, req_.files.file.path , function(err,id,stat){
    const req__ = Object.assign({}, createFileRequest);
    req__.headers.authorization = req_.headers.authorization;
    req__.json = {
         file: id,
         created_on: new Date()
     }
     console.log(req__);
     request(req__, function (err, res, body){

      if(err){
        fs.unlink(req_.files.file.path, function(err){
            storage.remove(id);
            if(err){
              res_.status(500).json({fileId: null, message: 'Server Error'})
            }else{
              res_.status(401).json({fileId: null, message: 'You are not Authorized to upload Files'});
            }

        });
      }else{
        fs.unlink(req_.files.file.path, function(err){
            if(err){
              res_.status(500).json({fileId: null, message: 'Server Error'})
            }else{
              res_.status(200).json({fileId: id, message: 'File Creation Succeeded'});
            }
        });
      }
    })
	});
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
  const fileId = req.query.fileId;
  storage.remove(fileId, function(err){
    if(err){
      res.status(500).json({fileId: fileId, message: 'File Deletion Failed'})
    } else {
      res.status(200).json({fileId: fileId, message: 'File Deletion Succeeded'})
    }
  });
});

app.get('/api/file/list',function(req,res){
	storage.listing(function(err,arr){
    if(err){
      res.status(500).json({files: null, message: 'File List Retrieval Failed'})
    } else {
      res.status(200).json({files: arr, message: 'File List Retrieval Succeeded'});
    }

	});
});

app.get('/api/file?:fileId',function(req,res){
  const fileId = req.query.fileId;
  storage.stat(fileId, function(err, stat) {
    if(err){
      res.status(500).json({message: 'File Retrieval Failed'});
    }else{
      res.set('Content-type',stat.type);
  		res.set('Access-Control-Expose-Headers','Content-Disposition,Content-Length,Content-Type');
  		res.set('Content-disposition', 'inline; filename=' + stat.name);
  		storage.pipe(fileId,res);
    }
	});
});

app.listen(CONFIG.SERVER_PORT, function () {
  console.log('File Storage Running on port 3005!');
});
