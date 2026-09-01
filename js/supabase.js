const SUPABASE_URL = "https://supabase.com/dashboard/project/dhljvtkwezwpgvrwzktl";
const SUPABASE_PUBLISHABLE_KEY = "sb_publishable_8GLp14BROeLhQmQotK3SiA_-YG-GOjG";

const supabaseClient = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY
);