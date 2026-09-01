const SUPABASE_URL = "https://dhljvtkwezwpgvrwzktl.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_8GLp14BROeLhQmQotK3SiA_-YG-GOjG";

const supabaseClient = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY
);