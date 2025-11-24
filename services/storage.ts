import { AppState, Product, Supplier, Sale, Purchase, ShoppingListItem, Comanda } from '../types';

// MOCK DATA PARA INICIALIZAÇÃO
const INITIAL_SUPPLIERS: Supplier[] = [
  { id: '1', name: 'Distribuidora Silva', contact: 'João Silva', email: 'joao@silva.com' },
  { id: '2', name: 'Hortifruti Central', contact: 'Maria', email: 'maria@horti.com' },
  { id: '3', name: 'Casa de Carnes', contact: 'Carlos', email: 'carlos@carnes.com' },
];

const INITIAL_PRODUCTS: Product[] = [
  { id: '101', name: 'Pão de Xis', type: 'insumo', unit: 'un', price: 0, cost: 1.50, stock: 100, minStock: 50, supplierId: '1', category: 'Padaria' },
  { id: '102', name: 'Hambúrguer Bovino', type: 'insumo', unit: 'un', price: 0, cost: 2.50, stock: 80, minStock: 40, supplierId: '3', category: 'Carnes' },
  { id: '103', name: 'Milho (Lata/Granel)', type: 'insumo', unit: 'g', price: 0, cost: 0.02, stock: 5000, minStock: 1000, supplierId: '2', category: 'Mercearia' },
  { id: '104', name: 'Ervilha (Lata/Granel)', type: 'insumo', unit: 'g', price: 0, cost: 0.02, stock: 5000, minStock: 1000, supplierId: '2', category: 'Mercearia' },
  { id: '105', name: 'Ovo', type: 'insumo', unit: 'un', price: 0, cost: 0.50, stock: 120, minStock: 30, supplierId: '2', category: 'Mercearia' },
  { id: '106', name: 'Coca-Cola Lata', type: 'insumo', unit: 'un', price: 6.00, cost: 2.50, stock: 48, minStock: 24, supplierId: '1', category: 'Bebidas' },
  { 
    id: '201', name: 'X-Completo', type: 'prato', unit: 'un', price: 28.00, cost: 0, stock: 0, minStock: 0, supplierId: '', category: 'Lanches',
    recipe: [
      { ingredientId: '101', quantity: 1 },
      { ingredientId: '102', quantity: 1 },
      { ingredientId: '103', quantity: 50 },
      { ingredientId: '104', quantity: 50 },
      { ingredientId: '105', quantity: 1 },
    ]
  },
  { 
    id: '202', name: 'Coca-Cola Lata', type: 'prato', unit: 'un', price: 6.00, cost: 2.50, stock: 0, minStock: 0, supplierId: '', category: 'Bebidas',
    recipe: [{ ingredientId: '106', quantity: 1 }] 
  }
];

const LOCAL_STORAGE_KEY = 'lanchonete_app_state_v4';

// CONFIGURAÇÃO: Mude para true quando tiver o backend rodando
const USE_API = false; 
const API_URL = 'http://localhost:3001/api';

export const storageService = {
  
  loadState: async (): Promise<AppState> => {
    if (USE_API) {
      try {
        // Exemplo de chamada real para o backend
        const response = await fetch(`${API_URL}/initial-state`);
        const data = await response.json();
        // Você precisaria mapear os dados do banco para o formato do AppState aqui
        // Por enquanto, retornamos um mock para não quebrar sem backend
        return {
           products: data.products,
           suppliers: data.suppliers,
           sales: [],
           purchases: [],
           shoppingList: [],
           activeComandas: []
        };
      } catch (e) {
        console.error("Erro ao conectar na API", e);
        return getMockState();
      }
    } else {
      // Modo LocalStorage (Atual)
      const saved = localStorage.getItem(LOCAL_STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (!parsed.activeComandas) return { ...parsed, activeComandas: [] };
        return parsed;
      }
      return getMockState();
    }
  },

  saveState: async (state: AppState): Promise<void> => {
    if (USE_API) {
      // No modo API, não salvamos o ESTADO INTEIRO.
      // O App.tsx deve chamar endpoints específicos (ex: POST /sales)
      // Esta função ficaria vazia ou salvaria apenas preferências locais
      console.log("Modo API: O salvamento deve ser granular (por transação).");
    } else {
      localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(state));
    }
  },

  // Exemplo de método específico para API
  syncSale: async (sale: Sale) => {
    if (USE_API) {
      await fetch(`${API_URL}/sales`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(sale)
      });
    }
  }
};

function getMockState(): AppState {
  return {
    products: INITIAL_PRODUCTS,
    suppliers: INITIAL_SUPPLIERS,
    sales: [],
    purchases: [],
    shoppingList: [],
    activeComandas: []
  };
}
