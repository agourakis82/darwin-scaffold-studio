// AI Chat state management
import { writable, derived } from 'svelte/store';

export interface ChatMessage {
  id: string;
  role: 'user' | 'assistant' | 'system' | 'error';
  content: string;
  timestamp: Date;
  toolsUsed?: string[];
  suggestions?: string[];
}

// Chat history
export const chatHistory = writable<ChatMessage[]>([]);

// Is AI typing/thinking
export const isTyping = writable<boolean>(false);

// Current agent type
export const currentAgent = writable<'design' | 'analysis' | 'synthesis'>('design');

// Derived: Last message
export const lastMessage = derived(chatHistory, ($history) => {
  return $history.length > 0 ? $history[$history.length - 1] : null;
});

// Derived: Has conversation
export const hasConversation = derived(chatHistory, ($history) => {
  return $history.length > 0;
});

// Actions
export function addMessage(message: Omit<ChatMessage, 'id' | 'timestamp'>) {
  const newMessage: ChatMessage = {
    ...message,
    id: crypto.randomUUID(),
    timestamp: new Date(),
  };
  chatHistory.update((history) => [...history, newMessage]);
  return newMessage.id;
}

export function updateMessage(id: string, updates: Partial<ChatMessage>) {
  chatHistory.update((history) =>
    history.map((msg) => (msg.id === id ? { ...msg, ...updates } : msg))
  );
}

export function clearChat() {
  chatHistory.set([]);
}

export function setAgent(agent: 'design' | 'analysis' | 'synthesis') {
  currentAgent.set(agent);
}

// Suggestion chips for quick actions
export const suggestionChips = [
  'Optimize for bone regeneration',
  'Increase porosity to 85%',
  'Generate gyroid scaffold',
  'What pore size is best for cartilage?',
  'Analyze current design',
  'Export to STL',
  'Check Q1 validation',
  'Recommend fabrication method',
];
