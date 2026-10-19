// Uses the existing editor's Export bundle action and html-to-image pipeline.
// PW_MODULE points to an installed Playwright package; no custom screenshot renderer.
const {chromium}=require(process.env.PW_MODULE || 'playwright');
const fs=require('node:fs');
const path=require('node:path');
(async()=>{
 const device=process.argv[2];
 if(!['iphone','ipad'].includes(device))throw new Error('Choose iphone or ipad');
 const root=path.resolve(__dirname,'../../../..');
 const base=path.resolve(__dirname,'..');
 const config=JSON.parse(fs.readFileSync(path.join(base,'editor-project.json')));
 for(const locale of config.locales)for(const slide of config.slidesByDevice[device]){
  const asset=path.join(root,'Product/AppStore/ScreenshotsEditor/public',slide.screenshot.replace('{locale}',locale));
  if(!fs.existsSync(asset))throw new Error('Missing real UI capture: '+asset);
 }
 const projectFile=path.join(root,'Product/AppStore/ScreenshotsEditor/app-store-screenshots.json');
 const previous=fs.readFileSync(projectFile);
 let browser;
 try{
  fs.writeFileSync(projectFile,JSON.stringify(config,null,2)+'\n');
  browser=await chromium.launch({headless:true,channel:'chrome'});
  const page=await browser.newPage({viewport:{width:1500,height:1000},acceptDownloads:true});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://127.0.0.1:3026');
  const button=page.getByRole('button',{name:'Export bundle',exact:true});
  await button.waitFor({timeout:60000});
  // Read current rendered controls before selecting the intended device.
  console.log((await page.locator('body').innerText()).slice(0,180));
  const chooser=page.getByRole('combobox').first();
  await chooser.click();
  console.log(await page.getByRole('listbox').innerText());
  await page.getByRole('option',{name:device==='ipad'?'iPad':'iPhone',exact:true}).click();
  await button.waitFor({state:'visible'});
  const downloadPromise=page.waitForEvent('download',{timeout:900000});
  await button.click();
  const download=await downloadPromise;
  await download.saveAs(path.join(base,device+'-export.zip'));
  console.log('Saved',device,'bundle',download.suggestedFilename());
  if(errors.length)throw new Error(errors.join('\n'));
  console.log((await page.locator('body').innerText()).slice(-500));
 }finally{
  try { if(browser) await browser.close(); }
  finally { fs.writeFileSync(projectFile,previous); }
 }
})().catch(e=>{console.error(e.message);process.exit(1)});
