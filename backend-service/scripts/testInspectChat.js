require('dotenv').config();
const adminController = require('../Controllers/admin.controller');

const req = {
  params: {
    chatId: 'ec121649-b453-4c52-a829-d020c1c886bf'
  }
};

const res = {
  statusCode: 200,
  status(code) {
    this.statusCode = code;
    return this;
  },
  json(data) {
    console.log("STATUS CODE:", this.statusCode);
    console.log(JSON.stringify(data, null, 2));
    process.exit(0);
  }
};

adminController.getChatMessages(req, res).catch(err => {
  console.error(err);
  process.exit(1);
});
