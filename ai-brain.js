require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Initialize the AI with your API key
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// This is the core function that talks to the AI
async function generateTestPlan(command) {
  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

  // This is the "prompt". We give the AI its instructions and rules here.
  const prompt = `
    You are an expert test automation assistant. Your task is to convert a plain English command into a structured JSON test plan for Playwright.

    The application is a simple To-Do list app.
    Here are the available UI elements and their CSS selectors:
    - Input field for new tasks: "#task-input"
    - The 'Add Task' button: "#add-button"
    - The list where tasks appear: "#task-list"
    - Any individual task item in the list: "#task-list li"

    Here are the actions you can include in your plan:
    1. "fill": To type text into an input field. Requires a 'selector' and a 'value'.
    2. "click": To click a button. Requires a 'selector'.
    3. "expectText": To check if an element contains specific text. Requires a 'selector' and a 'value'.

    Based on the user's command, generate a JSON array of steps. Do not include any explanation, just the raw JSON.

    User Command: "${command}"
  `;

  const result = await model.generateContent(prompt);
  const response = await result.response;
  const text = response.text();

  // Clean up the response from the AI and parse it as JSON
  const cleanedJson = text.replace(/```json/g, '').replace(/```/g, '').trim();
  return JSON.parse(cleanedJson);
}

// Make the function available to other files
module.exports = { generateTestPlan };