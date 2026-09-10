const {test, expect} = require('@playwright/test');
const sidebar = page => page.locator('.sidebar-nav');
async function ready(page) { await expect(sidebar(page).getByRole('link',{name:'Gallery',exact:true})).toBeVisible(); }
async function noOverflow(page) {
  expect(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1)).toBe(true);
}
test('desktop layout, nested routes, relative links and anchors', async ({page}) => {
  const errors = []; page.on('pageerror', e => errors.push(e.message));
  await page.goto('./'); await ready(page);
  expect((await page.locator('.sidebar').boundingBox()).x).toBe(0);
  await noOverflow(page);
  const hero = page.locator('.hero-image');
  await expect(hero).toBeVisible();
  expect(await hero.evaluate(img => img.complete && img.naturalWidth >= 3000)).toBe(true);
  const box = await hero.boundingBox(); const article = await page.locator('.markdown-section').boundingBox();
  expect(Math.abs(box.x + box.width/2 - article.x - article.width/2)).toBeLessThan(2);
  await sidebar(page).getByRole('link',{name:'Selector overview',exact:true}).click();
  await expect(page.locator('.markdown-section h1')).toHaveText('Selector overview');
  await page.locator('.markdown-section').getByRole('link',{name:'exact selection',exact:true}).click();
  await expect(page).toHaveURL(/pages\/selectors\/exact/);
  await expect(page.locator('.markdown-section h1')).toContainText('Exact');
  await sidebar(page).getByRole('link',{name:'Gallery',exact:true}).click();
  await expect(page.locator('.gallery-card')).toHaveCount(12);
  await page.locator('.gallery-card').nth(3).click();
  await expect(page).toHaveURL(/id=view-04-two-levels/);
  await expect(page.locator('#view-04-two-levels')).toBeInViewport();
  await expect(page.locator('pre code.lang-r')).toHaveCount(13);
  // Scroll each lazy image into view before checking its decoded dimensions.
  for (const img of await page.locator('.markdown-section img').all()) {
    await img.scrollIntoViewIfNeeded();
    await expect.poll(() => img.evaluate(i => i.complete && i.naturalWidth > 0)).toBe(true);
  }
  await noOverflow(page); expect(errors).toEqual([]);
});
test('legacy malformed route resolves to the intended article', async ({page}) => {
  await page.goto('./#/?id=%2fpages%2fconcepts'); await ready(page);
  await expect(page).toHaveURL(/#\/pages\/concepts$/);
  await expect(page.locator('.markdown-section h1')).toContainText('Concepts');
});
test('mobile menu opens at left and navigates', async ({page}) => {
  await page.setViewportSize({width:390,height:844});
  await page.goto('./'); await expect(page.locator('.markdown-section h1')).toBeVisible();
  await page.locator('.sidebar-toggle').click();
  await ready(page);
  await expect.poll(async () => Math.round((await page.locator('.sidebar').boundingBox()).x)).toBe(0);
  await sidebar(page).getByRole('link',{name:'Gallery',exact:true}).click();
  await expect(page.locator('.markdown-section h1')).toHaveText('Gallery');
  await expect(page.locator('body')).not.toHaveClass(/close/);
  await noOverflow(page);
});
