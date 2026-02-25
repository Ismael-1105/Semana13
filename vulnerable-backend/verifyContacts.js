/*
 * Simple script to test the /contacts endpoint of the vulnerable backend.
 * Usage: node verifyContacts.js
 * It will POST a dummy contact and then GET the list of contacts to confirm
 * the new entry appears. Finally it will DELETE all contacts if desired.
 */

const axios = require('axios');

const api = axios.create({
  baseURL: 'http://localhost:3000',
  timeout: 5000,
  headers: { 'Content-Type': 'application/json' }
});

async function run() {
  try {
    console.log('Posting test contact...');
    const fake = {
      displayName: 'Test User',
      phones: ['+123456789'],
      emails: ['test@example.com']
    };
    const postRes = await api.post('/contacts', fake);
    console.log('POST response:', postRes.data);

    console.log('Retrieving all contacts...');
    const getRes = await api.get('/contacts');
    console.log('Contacts on server:', getRes.data);

    if (Array.isArray(getRes.data)) {
      const found = getRes.data.find(c => c.displayName === fake.displayName);
      if (found) {
        console.log('✅ Test contact found on server!');
      } else {
        console.log('❌ Test contact NOT found.');
      }
    }

    // optionally clean up
    // await api.delete('/contacts');
    // console.log('All contacts deleted (cleanup).');

  } catch (err) {
    console.error('Error during verification:', err.response ? err.response.data : err.message);
  }
}

run();
