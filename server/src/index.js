import http from 'node:http';

const port = Number(process.env.PORT || 8787);
const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';

const server = http.createServer(async (request, response) => {
  try {
    setCorsHeaders(response);

    if (request.method === 'OPTIONS') {
      response.writeHead(204);
      response.end();
      return;
    }

    const url = new URL(request.url || '/', `http://${request.headers.host}`);

    if (request.method === 'GET' && url.pathname === '/health') {
      sendJson(response, 200, { ok: true, service: 'waiyudao-ai-server' });
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/translate') {
      await handleTranslate(request, response);
      return;
    }

    sendJson(response, 404, { error: 'Not found' });
  } catch (error) {
    sendJson(response, 500, {
      error: error instanceof Error ? error.message : 'Internal server error',
    });
  }
});

server.listen(port, () => {
  console.log(`Waiyudao AI server listening on http://localhost:${port}`);
});

async function handleTranslate(request, response) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    sendJson(response, 503, {
      error: 'OPENAI_API_KEY is not configured on the server.',
    });
    return;
  }

  const body = await readJson(request);
  const text = typeof body.text === 'string' ? body.text.trim() : '';
  if (!text) {
    sendJson(response, 400, { error: 'text is required.' });
    return;
  }

  const result = await translateWithOpenAI({ apiKey, text });
  sendJson(response, 200, result);
}

async function translateWithOpenAI({ apiKey, text }) {
  const openaiResponse = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      input: [
        {
          role: 'system',
          content:
            'You are a careful language tutor for a Chinese learner. Return only valid JSON that matches the requested schema. Translate naturally, not word-for-word. Korean must include honorific and casual variants, plus romanized pronunciation.',
        },
        {
          role: 'user',
          content: `Translate this Chinese sentence: ${text}`,
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'waiyudao_translation',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: [
              'source',
              'english',
              'koreanHonorific',
              'koreanCasual',
              'koreanPronunciation',
              'usageNote',
            ],
            properties: {
              source: { type: 'string' },
              english: { type: 'string' },
              koreanHonorific: { type: 'string' },
              koreanCasual: { type: 'string' },
              koreanPronunciation: { type: 'string' },
              usageNote: { type: 'string' },
            },
          },
        },
      },
    }),
  });

  const payload = await openaiResponse.json();
  if (!openaiResponse.ok) {
    throw new Error(payload.error?.message || 'OpenAI request failed.');
  }

  const outputText = extractOutputText(payload);
  const result = JSON.parse(outputText);

  return {
    source: String(result.source || text),
    english: String(result.english || ''),
    koreanHonorific: String(result.koreanHonorific || ''),
    koreanCasual: String(result.koreanCasual || ''),
    koreanPronunciation: String(result.koreanPronunciation || ''),
    usageNote: String(result.usageNote || ''),
  };
}

function extractOutputText(payload) {
  if (typeof payload.output_text === 'string') return payload.output_text;

  for (const output of payload.output || []) {
    for (const content of output.content || []) {
      if (typeof content.text === 'string') return content.text;
    }
  }

  throw new Error('OpenAI response did not include text output.');
}

async function readJson(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  return JSON.parse(raw);
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, { 'Content-Type': 'application/json' });
  response.end(JSON.stringify(body));
}

function setCorsHeaders(response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}
