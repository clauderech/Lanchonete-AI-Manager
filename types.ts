
export interface Supplier {
  id: string;
  name: string;
  contact: string;
  email: string;
}

export type MeasurementUnit = 'un' | 'kg' | 'g' | 'l' | 'ml';

export interface RecipeItem {
  ingredientId: string;
  quantity: number;
}

export interface Product {
  id: string;
  name: string;
  type: 'insumo' | 'prato'; // 'insumo' = bought/stocked, 'prato' = sold/composed
  price: number; // Selling price (0 for internal ingredients usually)
  cost: number; // Buying cost
  stock: number; // Current quantity in stock
  minStock: number;
  unit: MeasurementUnit;
  supplierId: string;
  category: string;
  recipe?: RecipeItem[]; // Only for 'prato'
}

export interface CartItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export interface ShoppingListItem {
  id: string;
  productId: string;
  quantity: number;
}

export interface Sale {
  id: string;
  date: string;
  items: CartItem[];
  total: number;
  paymentMethod: 'cash' | 'card' | 'pix';
  customerName?: string; // Optional for quick sales, required for comandas
}

export interface Comanda {
  id: string;
  customerName: string;
  openedAt: string; // ISO Date string
  items: CartItem[];
  total: number;
  status: 'open';
}

export interface Purchase {
  id: string;
  date: string;
  supplierId: string;
  items: CartItem[]; // unitPrice here represents cost
  total: number;
  status: 'ordered' | 'received';
}

export interface AppState {
  products: Product[];
  suppliers: Supplier[];
  sales: Sale[];
  purchases: Purchase[];
  shoppingList: ShoppingListItem[];
  activeComandas: Comanda[];
}

export type PageView = 'dashboard' | 'pos' | 'inventory' | 'purchases' | 'suppliers' | 'shopping-list';
