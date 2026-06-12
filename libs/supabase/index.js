/**
 * Supabase 统一入口 - 珈邻
 */

import supabaseMini from './supabase-mini.js'

export const auth = supabaseMini.auth
export const storage = supabaseMini.storage
export const db = supabaseMini.db

export default supabaseMini
