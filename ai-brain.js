// ai-brain.js
require('dotenv').config();
const OpenAI = require('openai');

// Initialize OpenAI with your API key
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function generateTestPlan(command) {
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

    Based on the user's command, generate a JSON array of steps. Respond with nothing but the raw JSON object.
  `;

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini", // A fast and reliable model
    messages: [
      { role: "system", content: prompt },
      { role: "user", content: command }
    ],
    response_format: { type: "json_object" }, // Ask for a JSON response directly
  });

  const planJsonString = response.choices[0].message.content;
  // The OpenAI API returns the plan nested inside a root object, so we extract it.
  const plan = JSON.parse(planJsonString);
  return plan.steps; // Assuming the AI wraps the plan in a 'steps' array
}

module.exports = { generateTestPlan };