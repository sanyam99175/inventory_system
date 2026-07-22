const express = require("express");
const puppeteer = require("puppeteer");

const app = express();
app.use(express.json());

let page;

async function initializeWhatsapp() {
  const browser = await puppeteer.launch({
    headless: false,
    userDataDir: "./chrome-profile",
    defaultViewport: null,
  });

  page = await browser.newPage();

  await page.goto("https://web.whatsapp.com", {
    waitUntil: "networkidle2",
  });

  console.log("WhatsApp ready");
}

async function sendMessage(chatName, message) {
  const searchBox = await page.waitForSelector(
    'input[placeholder="Search or start a new chat"]'
  );

  await searchBox.click();

  await page.keyboard.down("Meta");
  await page.keyboard.press("A");
  await page.keyboard.up("Meta");
  await page.keyboard.press("Backspace");

  await searchBox.type(chatName);

  await new Promise(resolve => setTimeout(resolve, 1500));

  await page.keyboard.press("Enter");

  await new Promise(resolve => setTimeout(resolve, 1000));

  const editableElements = await page.$$(
    'div[contenteditable="true"]'
  );

  const messageBox = editableElements[editableElements.length - 1];

    await messageBox.click();

    await page.evaluate((text) => {
    const active = document.activeElement;

    active.textContent = text;

    active.dispatchEvent(
        new InputEvent("input", {
        bubbles: true,
        inputType: "insertText",
        data: text
        })
    );
    }, message);

    await new Promise(resolve => setTimeout(resolve, 1000));

    await page.keyboard.press("Enter");
}

app.post("/send-message", async (req, res) => {
  try {
    const { chat, message } = req.body;

    await sendMessage(chat, message);

    res.json({
      success: true,
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

initializeWhatsapp().then(() => {
  app.listen(3001, () => {
    console.log("Server running on port 3001");
  });
});