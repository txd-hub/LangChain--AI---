<script setup lang="ts">
import { nextTick, ref } from "vue";
import { streamChat } from "./api";

type Message = { id: number; role: "user" | "assistant"; content: string; pending?: boolean };

const messages = ref<Message[]>([
  { id: 1, role: "assistant", content: "你好，我是本地 AI 助手。" }
]);
const input = ref("");
const sending = ref(false);
const panel = ref<HTMLElement | null>(null);
let messageId = 2;

async function scrollToBottom() {
  await nextTick();
  if (panel.value) panel.value.scrollTop = panel.value.scrollHeight;
}

async function sendMessage() {
  const question = input.value.trim();
  if (!question || sending.value) return;

  messages.value.push({ id: messageId++, role: "user", content: question });
  const reply: Message = { id: messageId++, role: "assistant", content: "", pending: true };
  messages.value.push(reply);
  input.value = "";
  sending.value = true;
  await scrollToBottom();

  try {
    await streamChat(question, {
      onToken: (token) => { reply.content += token; void scrollToBottom(); },
      onError: (message) => { reply.content += `\n\n错误：${message}`; }
    });
    if (!reply.content) reply.content = "模型没有返回内容。";
  } catch (error) {
    reply.content = `请求失败：${error instanceof Error ? error.message : "未知错误"}`;
  } finally {
    reply.pending = false;
    sending.value = false;
    await scrollToBottom();
  }
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    void sendMessage();
  }
}
</script>

<template>
  <main class="app-shell">
    <header class="topbar">
      <h1>本地 AI 问答</h1>
      <span>llama.cpp · Qwen2.5-0.5B</span>
    </header>

    <section ref="panel" class="message-panel" aria-live="polite">
      <article v-for="message in messages" :key="message.id" class="message" :class="message.role">
        <div class="message-label">{{ message.role === "user" ? "你" : "AI" }}</div>
        <div class="bubble"><span>{{ message.content }}</span><i v-if="message.pending" class="cursor" /></div>
      </article>
    </section>

    <form class="composer" @submit.prevent="sendMessage">
      <textarea v-model="input" rows="2" maxlength="4000" placeholder="输入问题，Enter 发送，Shift + Enter 换行" :disabled="sending" @keydown="onKeydown" />
      <button type="submit" :disabled="sending || !input.trim()" aria-label="发送">发送</button>
    </form>
  </main>
</template>
