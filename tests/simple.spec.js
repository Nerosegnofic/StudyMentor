// tests/simple.spec.js
const { test, expect, _electron } = require('@playwright/test');
const { generateTestPlan } = require('../ai-brain.js');

test('should execute a test plan from the AI', async () => {
  // 1. Define the high-level command in plain English
  const command = "Add a task 'Buy groceries' to the list and then verify that the task appears in the list.";

  console.log('Asking AI to generate a test plan for:', command);

  // 2. Call the AI brain to get the plan
  const testPlan = await generateTestPlan(command);
  console.log('AI returned the following plan:', JSON.stringify(testPlan, null, 2));

  // 3. Launch the app and execute the plan
  const electronApp = await _electron.launch({ args: ['.'] });
  const window = await electronApp.firstWindow();

  // 4. Loop through the steps from the AI and execute them
  for (const step of testPlan) {
    console.log(`Executing step: ${step.action}`);
    switch (step.action) {
      case 'fill':
        await window.locator(step.selector).fill(step.value);
        break;
      case 'click':
        await window.locator(step.selector).click();
        break;
      case 'expectText':
        const element = window.locator(step.selector);
        await expect(element).toHaveText(step.value);
        break;
      default:
        throw new Error(`Unknown action: ${step.action}`);
    }
  }

  console.log('Test plan executed successfully!');
  await electronApp.close();
});