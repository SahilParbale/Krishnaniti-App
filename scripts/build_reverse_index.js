const fs = require('fs');
const data = require('../lib/core/localization/translations_data.json');
const reverseMapMr = {};
const reverseMapHi = {};

function walk(enObj, mrObj, hiObj) {
  for (const k in enObj) {
    if (typeof enObj[k] === 'string') {
      const enVal = enObj[k].trim();
      if (enVal) {
        if (mrObj && mrObj[k] && typeof mrObj[k] === 'string') {
          reverseMapMr[enVal.toLowerCase()] = mrObj[k].trim();
        }
        if (hiObj && hiObj[k] && typeof hiObj[k] === 'string') {
          reverseMapHi[enVal.toLowerCase()] = hiObj[k].trim();
        }
      }
    } else if (typeof enObj[k] === 'object' && enObj[k] !== null) {
      walk(enObj[k], mrObj ? mrObj[k] : undefined, hiObj ? hiObj[k] : undefined);
    }
  }
}

walk(data.en, data.mr, data.hi);
console.log('Reverse map MR size:', Object.keys(reverseMapMr).length);
console.log('Reverse map HI size:', Object.keys(reverseMapHi).length);
console.log('Sample MR for "save":', reverseMapMr['save']);
console.log('Sample HI for "save":', reverseMapHi['save']);
console.log('Sample MR for "status":', reverseMapMr['status']);
console.log('Sample MR for "dashboard":', reverseMapMr['dashboard']);
