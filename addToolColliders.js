// add tools collider shapes to wrist_3_link
const fs = require('fs');

const additionalToolColliderFilenames =
      process.argv.slice(4) || process.argv.slice(4).length===0 ?
      [
	'CONVUM_SGE-M5-N-body-m.bbox.gltf',
	'CONVUM_SGE-M5-N-suction-m.bbox.gltf',
      ] :
      process.argv.slice(4);
const wrist3LinkName = process.argv[3] || 'wrist_3_link';

console.log('additionalToolColliderFilenames',additionalToolColliderFilenames,
	    'are added to',wrist3LinkName);

fs.readFile(process.argv[2] || 'update.json', (err, data) => {
  if (err) {
    console.error("Error reading file:", err);
    return;
  }
  const update = JSON.parse(data);
  const wrist3Link = update?.[wrist3LinkName];
  const visualArray = wrist3Link?.visual;
  if (visualArray) {
    additionalToolColliderFilenames.forEach((filename) => {
      const toolBodyVisual = structuredClone(visualArray[0]);
      toolBodyVisual.geometry.mesh.$.filename = filename;
      toolBodyVisual.origin.$.rpy = [0.5*Math.PI,0,0]; // for compensate blender's rotation
      toolBodyVisual.origin.$.xyz = [0,0,0];
      visualArray.push(toolBodyVisual);
    });
    fs.writeFileSync('update-with-tools-collider.json',
      JSON.stringify(update, null, 2));
    console.log("update-with-tools-collider.json has been created.");
  } else {
    console.error(`${wrist3LinkName}.visual not found in update.json`);
  }
});
