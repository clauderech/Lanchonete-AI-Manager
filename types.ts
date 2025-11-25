// =========================================
// LANCHONETE AI MANAGER - TIPOS UNIFICADOS
// =========================================
// Tipos TypeScript alinhados com database_unified.sql
// =========================================

export interface Supplier {
  id: string;
  name: string;
  contact: string;
  email: string;
  cnpj?: string;
  address?: string;
  city?: string;
  state?: string;
  created_at?: string;
  updated_at?: string;
}

export type MeasurementUnit = 'un' | 'kg' | 'g' | 'l' | 'ml';

export interface RecipeItem {
  ingredientId: string;
  quantity: number;
  unit?: string;
}

export interface Product {
  id: string;
  name: string;
  type: 'insumo' | 'prato';
  price: number;
  cost: number;
  stock: number;
  minStock: number;
  maxStock?: number;
  unit: MeasurementUnit;
  supplierId: string;
  category: string;
  description?: string;
  barcode?: string;
  isActive?: boolean;
  recipe?: RecipeItem[];
  created_at?: string;
  updated_at?: string;
}

export interface CartItem {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export type ShoppingListPriority = 'low' | 'medium' | 'high' | 'urgent';

export interface ShoppingListItem {
  id: string;
  productId: string;
  quantity: number;
  priority?: ShoppingListPriority;
  isPurchased?: boolean;
  purchasedAt?: string;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export type PaymentMethod = 'cash' | 'card' | 'pix' | 'credit';
export type PurchasePaymentMethod = 'cash' | 'card' | 'transfer' | 'check' | 'credit';

export interface Sale {
  id: string;
  date: string;
  items: CartItem[];
  total: number;
  subtotal: number;
  discount?: number;
  paymentMethod: PaymentMethod;
  customerName?: string;
  customerPhone?: string;
  comandaId?: string;
  notes?: string;
  created_at?: string;
}

export type ComandaStatus = 'open' | 'closed' | 'cancelled';
export type ComandaItemStatus = 'pending' | 'preparing' | 'ready' | 'delivered';

export interface ComandaItem extends CartItem {
  status?: ComandaItemStatus;
}

export interface Comanda {
  id: string;
  customerName: string;
  tableNumber?: string;
  openedAt: string;
  closedAt?: string;
  items: ComandaItem[];
  total: number;
  status: ComandaStatus;
  paymentMethod?: PaymentMethod;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export type PurchaseStatus = 'ordered' | 'received' | 'cancelled';

export interface Purchase {
  id: string;
  date: string;
  supplierId: string;
  items: CartItem[];
  total: number;
  status: PurchaseStatus;
  invoiceNumber?: string;
  paymentMethod?: PurchasePaymentMethod;
  paymentDate?: string;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export interface DailyAssets {
  id?: number;
  date: string;
  totalInicial: number;
  totalFinal: number;
  salesCash: number;
  salesCard: number;
  salesPix: number;
  salesCredit: number;
  totalSales: number;
  purchasesTotal: number;
  expensesTotal: number;
  lossesTotal: number;
  totalExpenses: number;
  netBalance: number;
  salesCount: number;
  itemsSold: number;
  averageTicket: number;
  isClosed: boolean;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export type ExpenseCategory = 
  | 'salarios' 
  | 'aluguel' 
  | 'energia' 
  | 'agua' 
  | 'gas' 
  | 'telefone' 
  | 'manutencao' 
  | 'impostos' 
  | 'outros';

export interface Expense {
  id: string;
  date: string;
  category: ExpenseCategory;
  description: string;
  amount: number;
  paymentMethod: Exclude<PurchasePaymentMethod, 'credit'>;
  supplierName?: string;
  invoiceNumber?: string;
  isRecurring: boolean;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export type CashRegisterStatus = 'open' | 'closed';

export interface CashRegister {
  id: string;
  openedAt: string;
  closedAt?: string;
  openedBy: string;
  closedBy?: string;
  initialAmount: number;
  expectedAmount: number;
  actualAmount: number;
  difference: number;
  status: CashRegisterStatus;
  notes?: string;
  created_at?: string;
  updated_at?: string;
}

export type MovementType = 'entrada' | 'saida' | 'ajuste' | 'perda' | 'devolucao';
export type ReferenceType = 'sale' | 'purchase' | 'adjustment' | 'recipe' | 'loss' | 'return';

export interface StockMovement {
  id?: number;
  productId: string;
  movementType: MovementType;
  quantity: number;
  previousStock: number;
  newStock: number;
  referenceType?: ReferenceType;
  referenceId?: string;
  costImpact?: number;
  notes?: string;
  createdBy?: string;
  created_at?: string;
}

export interface AppState {
  products: Product[];
  suppliers: Supplier[];
  sales: Sale[];
  purchases: Purchase[];
  shoppingList: ShoppingListItem[];
  activeComandas: Comanda[];
  dailyAssets?: DailyAssets[];
  expenses?: Expense[];
  cashRegister?: CashRegister;
}

export type PageView = 
  | 'dashboard' 
  | 'pos' 
  | 'inventory' 
  | 'purchases' 
  | 'suppliers' 
  | 'shopping-list'
  | 'financial'
  | 'expenses'
  | 'cash-register'
  | 'reports';
