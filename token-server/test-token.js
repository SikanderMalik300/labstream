#!/usr/bin/env node

// Test script to verify LiveKit token generation
const { AccessToken } = require('livekit-server-sdk');

const API_KEY = 'FCtPq5a/Bd/eyxyMlOyNhE4q8dncEll5vYNWJ2agpbY=';
const API_SECRET = 'FCtPq5a/Bd/eyxyMlOyNhE4q8dncEll5vYNWJ2agpbY=';

async function testTokenGeneration() {
  console.log('Testing LiveKit Token Generation');
  console.log('================================');
  console.log('API Key:', API_KEY);
  console.log('API Secret:', API_SECRET.substring(0, 20) + '...');
  console.log('');

  try {
    const at = new AccessToken(API_KEY, API_SECRET, {
      identity: 'test-user-123',
      name: 'John Doe',
      metadata: JSON.stringify({
        fullName: 'John Doe',
        universityId: 'STD001',
        role: 'student'
      })
    });

    at.addGrant({
      roomJoin: true,
      room: 'test-room',
      canPublish: true,
      canSubscribe: true,
      canPublishData: true
    });

    const token = await at.toJwt();

    console.log('✅ Token generated successfully!');
    console.log('');
    console.log('Token type:', typeof token);
    console.log('Token (first 50 chars):', String(token).substring(0, 50) + '...');
    console.log('Token length:', String(token).length);
    console.log('');
    console.log('Full token:');
    console.log(String(token));
  } catch (error) {
    console.error('❌ Error generating token:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

testTokenGeneration();
