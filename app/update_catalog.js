const fs = require('fs');
let code = fs.readFileSync('d:\\GP\\Graduation_Project\\StudyMentor\\app\\lib\\src\\data\\catalog\\avatar_items_catalog.dart', 'utf8');

const keys = {
  hair: 'topType',
  outfit: 'clotheType',
  bottom: 'clotheType', 
  shoes: 'clotheType',
  accessory: 'accessoriesType',
  background: 'style',
  special: 'style'
};

let indexCounts = {
  hair: 0,
  outfit: 0,
  bottom: 0,
  shoes: 0,
  accessory: 0,
  background: 0,
  special: 0
};

code = code.replace(/category: ItemCategory\.([^,]+),([^}]*?)unlockLevel: (\d+),/gs, (match, category, inner, unlock) => {
  let fmKey = keys[category] || 'topType';
  let fmIndex = indexCounts[category]++;
  return `category: ItemCategory.${category},${inner}unlockLevel: ${unlock},\n      fluttermojiKey: '${fmKey}',\n      fluttermojiIndex: ${fmIndex},`;
});

fs.writeFileSync('d:\\GP\\Graduation_Project\\StudyMentor\\app\\lib\\src\\data\\catalog\\avatar_items_catalog.dart', code);
