
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "accounts": {
                  Row: {
                    "archived_at": string | null,"created_at": string,"id": string,"is_default": boolean,"name": string,"opening_balance": number,"type": Database["public"]['Enums']["account_type"],"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"created_at"?: string,"id"?: string,"is_default"?: boolean,"name": string,"opening_balance"?: number,"type"?: Database["public"]['Enums']["account_type"],"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"created_at"?: string,"id"?: string,"is_default"?: boolean,"name"?: string,"opening_balance"?: number,"type"?: Database["public"]['Enums']["account_type"],"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    
                  ]
                },"audit_log": {
                  Row: {
                    "action": Database["public"]['Enums']["audit_action"],"after": Json | null,"before": Json | null,"created_at": string,"id": number,"row_id": string,"table_name": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "action": Database["public"]['Enums']["audit_action"],"after"?: Json | null,"before"?: Json | null,"created_at"?: string,"id"?: never,"row_id": string,"table_name": string,"user_id": string
                  }
                  Update: {
                    "action"?: Database["public"]['Enums']["audit_action"],"after"?: Json | null,"before"?: Json | null,"created_at"?: string,"id"?: never,"row_id"?: string,"table_name"?: string,"user_id"?: string
                  }
                  Relationships: [
                    
                  ]
                },"budget_lines": {
                  Row: {
                    "assigned_amount": number,"budget_month_id": string,"created_at": string,"envelope_id": string,"is_override": boolean,"note": string | null,"pct": number,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "assigned_amount"?: number,"budget_month_id": string,"created_at"?: string,"envelope_id": string,"is_override"?: boolean,"note"?: string | null,"pct"?: number,"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "assigned_amount"?: number,"budget_month_id"?: string,"created_at"?: string,"envelope_id"?: string,"is_override"?: boolean,"note"?: string | null,"pct"?: number,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "fk_budget_lines_budget_month"
      columns: ["user_id","budget_month_id"]
isOneToOne: false
      referencedRelation: "budget_months"
      referencedColumns: ["user_id","id"]
    },{
      foreignKeyName: "fk_budget_lines_envelope"
      columns: ["user_id","envelope_id"]
isOneToOne: false
      referencedRelation: "envelopes"
      referencedColumns: ["user_id","id"]
    }
                  ]
                },"budget_months": {
                  Row: {
                    "bhxh_salary": number | null,"closed_at": string | null,"created_at": string,"id": string,"income_gross": number | null,"income_planned": number,"month": string,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "bhxh_salary"?: number | null,"closed_at"?: string | null,"created_at"?: string,"id"?: string,"income_gross"?: number | null,"income_planned"?: number,"month": string,"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "bhxh_salary"?: number | null,"closed_at"?: string | null,"created_at"?: string,"id"?: string,"income_gross"?: number | null,"income_planned"?: number,"month"?: string,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    
                  ]
                },"envelope_aliases": {
                  Row: {
                    "alias": string,"created_at": string,"envelope_id": string,"id": string,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "alias": string,"created_at"?: string,"envelope_id": string,"id"?: string,"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "alias"?: string,"created_at"?: string,"envelope_id"?: string,"id"?: string,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "fk_envelope_aliases_envelope"
      columns: ["user_id","envelope_id"]
isOneToOne: false
      referencedRelation: "envelopes"
      referencedColumns: ["user_id","id"]
    }
                  ]
                },"envelope_groups": {
                  Row: {
                    "created_at": string,"id": string,"name": string,"sort_order": number,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"id"?: string,"name": string,"sort_order"?: number,"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"name"?: string,"sort_order"?: number,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    
                  ]
                },"envelope_movements": {
                  Row: {
                    "amount": number,"created_at": string,"from_envelope_id": string | null,"id": string,"month": string,"note": string | null,"reason": Database["public"]['Enums']["movement_reason"],"to_envelope_id": string | null,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "amount": number,"created_at"?: string,"from_envelope_id"?: string | null,"id"?: string,"month": string,"note"?: string | null,"reason": Database["public"]['Enums']["movement_reason"],"to_envelope_id"?: string | null,"user_id"?: string
                  }
                  Update: {
                    "amount"?: number,"created_at"?: string,"from_envelope_id"?: string | null,"id"?: string,"month"?: string,"note"?: string | null,"reason"?: Database["public"]['Enums']["movement_reason"],"to_envelope_id"?: string | null,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "fk_envelope_movements_from_envelope"
      columns: ["user_id","from_envelope_id"]
isOneToOne: false
      referencedRelation: "envelopes"
      referencedColumns: ["user_id","id"]
    },{
      foreignKeyName: "fk_envelope_movements_to_envelope"
      columns: ["user_id","to_envelope_id"]
isOneToOne: false
      referencedRelation: "envelopes"
      referencedColumns: ["user_id","id"]
    }
                  ]
                },"envelopes": {
                  Row: {
                    "archived_at": string | null,"created_at": string,"description": string | null,"group_id": string,"icon": string | null,"id": string,"name": string,"rollover": boolean,"sort_order": number,"target_amount": number | null,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "archived_at"?: string | null,"created_at"?: string,"description"?: string | null,"group_id": string,"icon"?: string | null,"id"?: string,"name": string,"rollover"?: boolean,"sort_order"?: number,"target_amount"?: number | null,"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "archived_at"?: string | null,"created_at"?: string,"description"?: string | null,"group_id"?: string,"icon"?: string | null,"id"?: string,"name"?: string,"rollover"?: boolean,"sort_order"?: number,"target_amount"?: number | null,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "fk_envelopes_group"
      columns: ["user_id","group_id"]
isOneToOne: false
      referencedRelation: "envelope_groups"
      referencedColumns: ["user_id","id"]
    }
                  ]
                },"settings": {
                  Row: {
                    "created_at": string,"default_account_id": string | null,"emergency_envelope_id": string | null,"emergency_target_months": number,"overspend_alert_pct": number,"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "created_at"?: string,"default_account_id"?: string | null,"emergency_envelope_id"?: string | null,"emergency_target_months"?: number,"overspend_alert_pct"?: number,"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "created_at"?: string,"default_account_id"?: string | null,"emergency_envelope_id"?: string | null,"emergency_target_months"?: number,"overspend_alert_pct"?: number,"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "fk_settings_default_account"
      columns: ["user_id","default_account_id"]
isOneToOne: false
      referencedRelation: "accounts"
      referencedColumns: ["user_id","id"]
    },{
      foreignKeyName: "fk_settings_emergency_envelope"
      columns: ["user_id","emergency_envelope_id"]
isOneToOne: false
      referencedRelation: "envelopes"
      referencedColumns: ["user_id","id"]
    }
                  ]
                },"transactions": {
                  Row: {
                    "account_id": string,"amount": number,"client_id": string | null,"created_at": string,"deleted_at": string | null,"envelope_id": string | null,"id": string,"merchant": string | null,"note": string | null,"occurred_at": string,"source": Database["public"]['Enums']["txn_source"],"status": Database["public"]['Enums']["txn_status"],"tags": (string)[],"to_account_id": string | null,"type": Database["public"]['Enums']["txn_type"],"updated_at": string,"user_id": string
                  }
                  ComputedFields: never
                  Insert: {
                    "account_id": string,"amount": number,"client_id"?: string | null,"created_at"?: string,"deleted_at"?: string | null,"envelope_id"?: string | null,"id"?: string,"merchant"?: string | null,"note"?: string | null,"occurred_at"?: string,"source"?: Database["public"]['Enums']["txn_source"],"status"?: Database["public"]['Enums']["txn_status"],"tags"?: (string)[],"to_account_id"?: string | null,"type": Database["public"]['Enums']["txn_type"],"updated_at"?: string,"user_id"?: string
                  }
                  Update: {
                    "account_id"?: string,"amount"?: number,"client_id"?: string | null,"created_at"?: string,"deleted_at"?: string | null,"envelope_id"?: string | null,"id"?: string,"merchant"?: string | null,"note"?: string | null,"occurred_at"?: string,"source"?: Database["public"]['Enums']["txn_source"],"status"?: Database["public"]['Enums']["txn_status"],"tags"?: (string)[],"to_account_id"?: string | null,"type"?: Database["public"]['Enums']["txn_type"],"updated_at"?: string,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "fk_transactions_account"
      columns: ["user_id","account_id"]
isOneToOne: false
      referencedRelation: "accounts"
      referencedColumns: ["user_id","id"]
    },{
      foreignKeyName: "fk_transactions_envelope"
      columns: ["user_id","envelope_id"]
isOneToOne: false
      referencedRelation: "envelopes"
      referencedColumns: ["user_id","id"]
    },{
      foreignKeyName: "fk_transactions_to_account"
      columns: ["user_id","to_account_id"]
isOneToOne: false
      referencedRelation: "accounts"
      referencedColumns: ["user_id","id"]
    }
                  ]
                }
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            [_ in never]: never
          }
          Enums: {
            "account_type": "asset"|"liability","audit_action": "insert"|"update"|"delete","movement_reason": "month_close"|"manual","txn_source": "quickadd"|"manual"|"shortcut"|"import"|"system","txn_status": "confirmed"|"pending","txn_type": "expense"|"income"|"transfer"
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            "account_type": ["asset", "liability"],"audit_action": ["insert", "update", "delete"],"movement_reason": ["month_close", "manual"],"txn_source": ["quickadd", "manual", "shortcut", "import", "system"],"txn_status": ["confirmed", "pending"],"txn_type": ["expense", "income", "transfer"]
          }
        }
} as const
