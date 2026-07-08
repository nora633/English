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

    if (request.method === 'POST' && url.pathname === '/api/check-dictation') {
      await handleExerciseCheck(request, response, 'dictation');
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/check-recall') {
      await handleExerciseCheck(request, response, 'recall');
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/generate-daily-lesson') {
      await handleGenerateDailyLesson(request, response);
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

async function handleGenerateDailyLesson(request, response) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    sendJson(response, 503, {
      error: 'OPENAI_API_KEY is not configured on the server.',
    });
    return;
  }

  const body = await readJson(request);
  const preferredStage =
    typeof body.preferredStage === 'string' ? body.preferredStage : 'daily';
  const durationMinutes = Number(body.durationMinutes || 15);
  const troubleSpots = Array.isArray(body.troubleSpots)
    ? body.troubleSpots.map((item) => String(item)).filter(Boolean)
    : [];

  const result = await generateDailyLessonWithOpenAI({
    apiKey,
    preferredStage,
    durationMinutes,
    troubleSpots,
  });
  sendJson(response, 200, result);
}

async function handleExerciseCheck(request, response, mode) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    sendJson(response, 503, {
      error: 'OPENAI_API_KEY is not configured on the server.',
    });
    return;
  }

  const body = await readJson(request);
  const target = typeof body.target === 'string' ? body.target.trim() : '';
  const answer = typeof body.answer === 'string' ? body.answer.trim() : '';
  const prompt = typeof body.prompt === 'string' ? body.prompt.trim() : '';

  if (!target || !answer) {
    sendJson(response, 400, { error: 'target and answer are required.' });
    return;
  }

  const result = await checkExerciseWithOpenAI({
    apiKey,
    mode,
    target,
    answer,
    prompt,
  });
  sendJson(response, 200, result);
}

async function generateDailyLessonWithOpenAI({
  apiKey,
  preferredStage,
  durationMinutes,
  troubleSpots,
}) {
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
            'You are designing a 15-minute English lesson for an adult Chinese learner. The learner likes sitcom-style daily life scenes, popular English songs, then later news and articles. Start easy and increase difficulty gradually. Return only valid JSON matching the schema. Use original content only; do not quote copyrighted lyrics or TV scripts.',
        },
        {
          role: 'user',
          content: [
            `Preferred stage: ${preferredStage}`,
            `Duration minutes: ${durationMinutes}`,
            `Recent trouble spots: ${troubleSpots.join(', ') || 'none'}`,
            'Create one daily lesson with exactly 5 listening lines, 4 key words, 3 grammar points, and 3 target chunks.',
          ].join('\n'),
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'waiyudao_daily_lesson',
          strict: true,
          schema: dailyLessonSchema(),
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
  return sanitizeDailyLesson(result, durationMinutes);
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

async function checkExerciseWithOpenAI({ apiKey, mode, target, answer, prompt }) {
  const task =
    mode === 'dictation'
      ? 'Check an English dictation answer against the exact target sentence. Ignore capitalization and minor punctuation. Focus on missing words, wrong words, word order, and contractions.'
      : 'Check an English recall answer from a Chinese prompt. Judge whether the meaning is correct and the English is natural. Do not require exact wording if the meaning is equivalent.';

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
            'You are a strict but encouraging English tutor for a Chinese learner. Return only valid JSON that matches the requested schema. Keep feedback short and actionable in Chinese.',
        },
        {
          role: 'user',
          content: [
            task,
            `Mode: ${mode}`,
            `Chinese prompt: ${prompt || 'N/A'}`,
            `Target/reference sentence: ${target}`,
            `Learner answer: ${answer}`,
          ].join('\n'),
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          name: 'waiyudao_exercise_check',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: [
              'score',
              'level',
              'summary',
              'reference',
              'correctedAnswer',
              'issues',
              'suggestions',
            ],
            properties: {
              score: { type: 'integer', minimum: 0, maximum: 100 },
              level: {
                type: 'string',
                enum: ['great', 'pass', 'needs_work'],
              },
              summary: { type: 'string' },
              reference: { type: 'string' },
              correctedAnswer: { type: 'string' },
              issues: {
                type: 'array',
                items: { type: 'string' },
              },
              suggestions: {
                type: 'array',
                items: { type: 'string' },
              },
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
    score: clampScore(result.score),
    level: normalizeLevel(result.level),
    summary: String(result.summary || ''),
    reference: String(result.reference || target),
    correctedAnswer: String(result.correctedAnswer || target),
    issues: normalizeStringList(result.issues),
    suggestions: normalizeStringList(result.suggestions),
  };
}

function clampScore(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return 0;
  return Math.max(0, Math.min(100, Math.round(parsed)));
}

function normalizeLevel(value) {
  if (value === 'great' || value === 'pass' || value === 'needs_work') {
    return value;
  }
  return 'needs_work';
}

function normalizeStringList(value) {
  if (!Array.isArray(value)) return [];
  return value.map((item) => String(item)).filter(Boolean);
}

function dailyLessonSchema() {
  return {
    type: 'object',
    additionalProperties: false,
    required: [
      'title',
      'durationMinutes',
      'completedMinutes',
      'theme',
      'keyWords',
      'grammarPoints',
      'targetChunks',
      'listeningLines',
    ],
    properties: {
      title: { type: 'string' },
      durationMinutes: { type: 'integer' },
      completedMinutes: { type: 'integer' },
      theme: {
        type: 'object',
        additionalProperties: false,
        required: [
          'title',
          'stage',
          'kind',
          'sourceHint',
          'focus',
          'difficulty',
          'previewTitle',
          'previewDescription',
          'sampleContent',
          'practiceSentences',
          'keyVocabulary',
        ],
        properties: {
          title: { type: 'string' },
          stage: {
            type: 'string',
            enum: ['daily', 'media', 'news', 'reading'],
          },
          kind: {
            type: 'string',
            enum: ['sitcom', 'song', 'dailyLife', 'news', 'article'],
          },
          sourceHint: { type: 'string' },
          focus: { type: 'string' },
          difficulty: { type: 'string' },
          previewTitle: { type: 'string' },
          previewDescription: { type: 'string' },
          sampleContent: { type: 'string' },
          practiceSentences: {
            type: 'array',
            items: { type: 'string' },
          },
          keyVocabulary: {
            type: 'array',
            items: { type: 'string' },
          },
        },
      },
      keyWords: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: [
            'word',
            'phonetic',
            'meaning',
            'usage',
            'example',
            'priority',
            'wordRoot',
            'memoryHint',
            'collocations',
            'relatedWords',
            'confusingPoint',
          ],
          properties: {
            word: { type: 'string' },
            phonetic: { type: 'string' },
            meaning: { type: 'string' },
            usage: { type: 'string' },
            example: { type: 'string' },
            priority: { type: 'string' },
            wordRoot: { type: 'string' },
            memoryHint: { type: 'string' },
            collocations: {
              type: 'array',
              items: { type: 'string' },
            },
            relatedWords: {
              type: 'array',
              items: { type: 'string' },
            },
            confusingPoint: { type: 'string' },
          },
        },
      },
      grammarPoints: {
        type: 'array',
        items: {
          type: 'object',
          additionalProperties: false,
          required: ['pattern', 'meaning', 'example', 'note'],
          properties: {
            pattern: { type: 'string' },
            meaning: { type: 'string' },
            example: { type: 'string' },
            note: { type: 'string' },
          },
        },
      },
      targetChunks: {
        type: 'array',
        items: { type: 'string' },
      },
      listeningLines: {
        type: 'array',
        items: { type: 'string' },
      },
    },
  };
}

function sanitizeDailyLesson(result, durationMinutes) {
  return {
    title: String(result.title || '今日 15 分钟听说训练'),
    durationMinutes: clampMinutes(result.durationMinutes, durationMinutes),
    completedMinutes: 0,
    theme: result.theme,
    keyWords: Array.isArray(result.keyWords) ? result.keyWords.slice(0, 4) : [],
    grammarPoints: Array.isArray(result.grammarPoints)
      ? result.grammarPoints.slice(0, 3)
      : [],
    targetChunks: Array.isArray(result.targetChunks)
      ? result.targetChunks.slice(0, 3)
      : [],
    listeningLines: Array.isArray(result.listeningLines)
      ? result.listeningLines.slice(0, 5)
      : [],
  };
}

function clampMinutes(value, fallback) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.max(5, Math.min(30, Math.round(parsed)));
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
