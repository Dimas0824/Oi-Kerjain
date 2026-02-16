import React, { useState, useEffect } from 'react';

// --- THEME CONFIGURATION ---
const theme = {
    bg: '#E0E5EC',
    textMain: '#2D3748',
    textSec: '#A0AEC0',
    accent: '#6B46C1', // Bold Purple
    danger: '#E53E3E',
    success: '#38A169',
    fontMono: 'monospace',
};

// --- COMPLEX SHADOW STYLES (INLINE FOR STABILITY) ---
const s = {
    // Container utama
    wrapper: {
        backgroundColor: theme.bg,
        color: theme.textMain,
        fontFamily: '"Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    },
    // Tombol Timbul (Convex) - Hard Edges
    neuHard: {
        backgroundColor: theme.bg,
        boxShadow: '6px 6px 12px #B8B9BE, -6px -6px 12px #FFFFFF',
        borderRadius: '20px',
        border: '1px solid rgba(255,255,255,0.2)',
    },
    // Tombol Ditekan (Concave/Inset) - Deep
    neuInset: {
        backgroundColor: theme.bg,
        boxShadow: 'inset 5px 5px 10px #B8B9BE, inset -5px -5px 10px #FFFFFF',
        borderRadius: '16px',
        border: '1px solid rgba(255,255,255,0.05)',
    },
    // Panel Datar (Flat Surface)
    neuFlat: {
        backgroundColor: theme.bg,
        boxShadow: '3px 3px 6px #B8B9BE, -3px -3px 6px #FFFFFF',
        borderRadius: '16px',
        border: '1px solid rgba(255,255,255,0.2)',
    },
    // Layar Digital (Super Inset)
    screenInset: {
        backgroundColor: '#D1D6DE',
        boxShadow: 'inset 2px 2px 5px #A3A7AE, inset -2px -2px 5px #FFFFFF',
        borderRadius: '8px',
        color: '#4A5568',
    },
    // LED Indicator (Glowing)
    ledOn: {
        background: 'radial-gradient(circle, #4FD1C5 0%, #38B2AC 100%)',
        boxShadow: '0 0 8px #4FD1C5, inset 1px 1px 2px rgba(255,255,255,0.5)',
    },
    ledRed: {
        background: 'radial-gradient(circle, #FC8181 0%, #E53E3E 100%)',
        boxShadow: '0 0 8px #FC8181, inset 1px 1px 2px rgba(255,255,255,0.5)',
    },
    ledOff: {
        background: '#CBD5E0',
        boxShadow: 'inset 1px 1px 2px rgba(0,0,0,0.2)',
    }
};

// --- CUSTOM SVG ICONS (Technical Style) ---
const IconGrid = () => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
        <rect x="3" y="3" width="7" height="7" rx="1" />
        <rect x="14" y="3" width="7" height="7" rx="1" />
        <rect x="14" y="14" width="7" height="7" rx="1" />
        <rect x="3" y="14" width="7" height="7" rx="1" />
    </svg>
);

const IconBolt = () => (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
    </svg>
);

const IconCheck = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round">
        <polyline points="20 6 9 17 4 12" />
    </svg>
);

const IconScrew = () => (
    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#A0AEC0" strokeWidth="3" opacity="0.6">
        <line x1="12" y1="5" x2="12" y2="19" />
        <line x1="5" y1="12" x2="19" y2="12" />
        <circle cx="12" cy="12" r="10" strokeWidth="2" />
    </svg>
);

const IconAlert = () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="12" y1="8" x2="12" y2="12"></line>
        <line x1="12" y1="16" x2="12.01" y2="16"></line>
    </svg>
);

const IconSearch = () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#A0AEC0" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
    </svg>
);

const IconCalendar = () => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#A0AEC0" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
        <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
        <line x1="16" y1="2" x2="16" y2="6"></line>
        <line x1="8" y1="2" x2="8" y2="6"></line>
        <line x1="3" y1="10" x2="21" y2="10"></line>
    </svg>
);

// --- NEW DASHBOARD COMPONENTS ---

// Integrated Control Unit (Updated with Priority Monitor)
const DashboardControlUnit = ({ progress, pending, criticalTask }) => {
    const r = 36;
    const circ = 2 * Math.PI * r;
    const strokePct = ((100 - progress) * circ) / 100;

    return (
        <div style={s.neuHard} className="w-full p-1 rounded-[24px] relative mb-6">
            {/* Inner Plate */}
            <div className="bg-[#E0E5EC] rounded-[20px] p-4 relative border border-white/40">
                {/* Decorative Screws */}
                <div className="absolute top-3 left-3"><IconScrew /></div>
                <div className="absolute top-3 right-3"><IconScrew /></div>
                <div className="absolute bottom-3 left-3"><IconScrew /></div>
                <div className="absolute bottom-3 right-3"><IconScrew /></div>

                {/* Header Label */}
                <div className="flex justify-center mb-4">
                    <div style={s.neuInset} className="px-4 py-1 rounded-full flex items-center gap-2">
                        {/* System Status LED: Green if 100%, Red blink if Critical task exists, else Green */}
                        <div
                            style={criticalTask ? s.ledRed : s.ledOn}
                            className={`w-1.5 h-1.5 rounded-full ${criticalTask ? 'animate-pulse' : ''}`}
                        ></div>
                        <span className="text-[9px] font-bold text-gray-500 uppercase tracking-widest">
                            {criticalTask ? 'ALERT: PRIORITY' : 'SYSTEM NOMINAL'}
                        </span>
                    </div>
                </div>

                <div className="flex items-center gap-6 px-2">
                    {/* LEFT: The Reactor Gauge */}
                    <div className="relative">
                        <div style={s.neuInset} className="w-32 h-32 rounded-full flex items-center justify-center shadow-inner">
                            {/* SVG Ring */}
                            <svg width="100" height="100" className="transform -rotate-90">
                                <circle cx="50" cy="50" r="36" stroke="#CBD5E0" strokeWidth="8" fill="transparent" />
                                <circle
                                    cx="50" cy="50" r="36"
                                    stroke="#6B46C1"
                                    strokeWidth="8"
                                    fill="transparent"
                                    strokeDasharray={circ}
                                    strokeDashoffset={strokePct}
                                    strokeLinecap="round"
                                    className="transition-all duration-1000 ease-out"
                                />
                            </svg>
                            {/* Inner Knob */}
                            <div style={s.neuHard} className="absolute w-16 h-16 rounded-full flex flex-col items-center justify-center z-10 shadow-lg">
                                <span className="text-xl font-black text-[#6B46C1]">{progress}%</span>
                            </div>
                        </div>
                    </div>

                    {/* RIGHT: Critical Task Monitor (Replaces Stats) */}
                    <div className="flex-1 flex flex-col h-32 justify-center">
                        <div className="flex justify-between items-end mb-1 px-1">
                            <span className="text-[9px] font-bold text-gray-400 uppercase">Primary Directive</span>
                            {criticalTask && <div className="text-red-500 animate-pulse"><IconAlert /></div>}
                        </div>

                        <div style={s.screenInset} className="flex-1 p-3 flex flex-col justify-center gap-1">
                            {criticalTask ? (
                                <>
                                    <span className="text-[9px] font-bold text-gray-400 uppercase tracking-wider mb-1">TARGET:</span>
                                    <h4 className="font-bold text-sm text-gray-700 leading-tight line-clamp-2">
                                        {criticalTask.title}
                                    </h4>

                                    <div className="mt-auto pt-2 border-t border-gray-400/20 flex justify-between items-center w-full">
                                        <span className={`text-[9px] font-mono font-bold ${criticalTask.priority === 'high' ? 'text-red-500' : 'text-gray-500'}`}>
                                            DUE: {criticalTask.deadline ? criticalTask.deadline.substring(5) : 'TODAY'}
                                        </span>
                                        <span className="text-[9px] font-mono text-gray-500">{criticalTask.time}</span>
                                    </div>
                                </>
                            ) : (
                                <div className="flex flex-col items-center justify-center h-full opacity-40">
                                    <span className="text-[10px] font-mono font-bold">STANDBY</span>
                                    <span className="text-[8px] uppercase">No critical targets</span>
                                </div>
                            )}
                        </div>
                    </div>
                </div>

                {/* Footer Info */}
                <div className="mt-4 flex justify-between items-center px-2">
                    <span className="text-[9px] font-bold text-gray-400 uppercase">Pending Tasks: <span className="text-[#6B46C1] text-xs">{pending}</span></span>
                    <div className="flex gap-1">
                        <div className={`w-1 h-3 rounded-full ${criticalTask ? 'bg-red-400' : 'bg-gray-300'}`}></div>
                        <div className={`w-1 h-3 rounded-full ${criticalTask ? 'bg-red-400' : 'bg-gray-300'}`}></div>
                        <div className={`w-1 h-3 rounded-full ${criticalTask ? 'bg-red-400' : 'bg-gray-300'}`}></div>
                    </div>
                </div>
            </div>
        </div>
    );
};

// 3. TASK CARTRIDGE
const TaskCartridge = ({ task, onToggle }) => (
    <div
        onClick={onToggle}
        style={s.neuHard}
        className={`
      p-1 flex items-stretch min-h-[100px] cursor-pointer transition-transform active:scale-[0.98]
      ${task.status === 'done' ? 'opacity-60' : ''}
    `}
    >
        {/* Side Grip / Status Indicator */}
        <div
            className={`w-2 rounded-l-xl mr-3 ${task.category === 'Work' ? 'bg-blue-400' : 'bg-orange-400'}`}
            style={{ boxShadow: 'inset -1px 0 2px rgba(0,0,0,0.1)' }}
        />

        <div className="flex-1 py-3 pr-4 flex flex-col justify-center gap-2">
            <div className="flex justify-between items-start">
                <h4 className={`font-bold text-sm text-gray-700 ${task.status === 'done' ? 'line-through' : ''}`}>
                    {task.title}
                </h4>
                {task.priority === 'high' && <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>}
            </div>

            {/* Description Block */}
            {task.description && (
                <p className="text-[10px] text-gray-500 leading-tight line-clamp-2 font-medium">
                    {task.description}
                </p>
            )}

            {/* Info Row embedded in 'screen' */}
            <div style={s.screenInset} className="flex items-center justify-between px-3 py-2 mt-1">
                <div className="flex items-center gap-3">
                    <span className="text-[10px] font-bold font-mono text-gray-500 flex items-center gap-1">
                        <span className="opacity-50">DUE:</span> {task.deadline || 'TODAY'}
                    </span>
                    <span className="text-[10px] font-bold font-mono text-gray-500">
                        {task.time}
                    </span>
                </div>
                <span className="text-[9px] font-bold uppercase text-gray-400 tracking-wider">{task.category}</span>
            </div>
        </div>

        {/* Toggle Button Area */}
        <div className="w-14 flex items-center justify-center border-l border-gray-200">
            <div
                style={task.status === 'done' ? { ...s.neuInset, backgroundColor: '#6B46C1' } : s.neuHard}
                className="w-8 h-8 rounded-lg flex items-center justify-center transition-all duration-300"
            >
                {task.status === 'done' && <IconCheck />}
            </div>
        </div>
    </div>
);

// --- MAIN APP ---
export default function App() {
    const [tasks, setTasks] = useState([
        { id: 1, title: 'System Architecture', description: 'Define microservices boundaries and database schema.', time: '09:00', deadline: '2023-11-01', category: 'Work', priority: 'high', status: 'active' },
        { id: 2, title: 'Client Workshop', description: 'Prepare slide deck for Q4 review.', time: '13:30', deadline: '2023-11-02', category: 'Work', priority: 'medium', status: 'active' },
        { id: 3, title: 'Car Service', description: 'Oil change and brake check.', time: '16:00', deadline: '2023-11-05', category: 'Personal', priority: 'low', status: 'done' },
    ]);

    const [activeFilter, setActiveFilter] = useState('All');
    const [searchQuery, setSearchQuery] = useState('');
    const [isSheetOpen, setIsSheetOpen] = useState(false);

    // New Task State
    const [newTask, setNewTask] = useState({
        title: '',
        description: '',
        time: '12:00',
        deadline: '',
        priority: 'medium',
        category: 'Work'
    });

    const doneCount = tasks.filter(t => t.status === 'done').length;
    const progress = Math.round((doneCount / tasks.length) * 100) || 0;

    // LOGIC: Find most critical task (High Priority > Nearest Deadline)
    const activeTasks = tasks.filter(t => t.status === 'active');
    const criticalTask = activeTasks.sort((a, b) => {
        // Priority Weight: High = 3, Medium = 2, Low = 1
        const pA = a.priority === 'high' ? 3 : a.priority === 'medium' ? 2 : 1;
        const pB = b.priority === 'high' ? 3 : b.priority === 'medium' ? 2 : 1;

        // Sort by Priority Descending
        if (pA !== pB) return pB - pA;

        // If Priority equal, sort by Date/Time Ascending
        const dateA = new Date((a.deadline || '2099-12-31') + ' ' + a.time);
        const dateB = new Date((b.deadline || '2099-12-31') + ' ' + b.time);
        return dateA - dateB;
    })[0];

    const filteredTasks = tasks.filter(t => {
        const matchesFilter = activeFilter === 'All' || t.category === activeFilter;
        const matchesSearch = t.title.toLowerCase().includes(searchQuery.toLowerCase());
        return matchesFilter && matchesSearch;
    });

    const toggleTask = (id) => {
        setTasks(tasks.map(t => t.id === id ? { ...t, status: t.status === 'done' ? 'active' : 'done' } : t));
    };

    const handleAddTask = () => {
        if (newTask.title) {
            setTasks([{
                id: Date.now(),
                ...newTask,
                status: 'active'
            }, ...tasks]);
            setNewTask({ title: '', description: '', time: '12:00', deadline: '', priority: 'medium', category: 'Work' });
            setIsSheetOpen(false);
        }
    };

    // Date formatting for Header
    const today = new Date();
    const dateString = today.toLocaleDateString('en-US', { day: 'numeric', month: 'short' }).toUpperCase();
    const dayString = today.toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase();

    return (
        <div className="min-h-screen flex items-center justify-center p-0 md:p-8" style={s.wrapper}>

            {/* RUGGED PHONE CONTAINER */}
            <div
                className="w-full h-screen md:h-[850px] md:w-[420px] flex flex-col relative overflow-hidden"
                style={{
                    backgroundColor: theme.bg,
                    borderRadius: window.innerWidth > 768 ? '40px' : '0',
                    boxShadow: window.innerWidth > 768 ? '25px 25px 50px #B8B9BE, -25px -25px 50px #FFFFFF' : 'none'
                }}
            >

                {/* === HEADER COMMAND BAR (REPLACED PROFILE) === */}
                <div className="pt-10 px-6 pb-6 z-10">
                    <div className="flex gap-4 h-16">
                        {/* Date Module */}
                        <div style={s.neuHard} className="w-1/3 flex flex-col justify-center px-4 relative overflow-hidden">
                            <div className="absolute top-2 right-2"><IconCalendar /></div>
                            <span className="text-[9px] font-bold text-gray-400 uppercase tracking-wider">{dayString}</span>
                            <span className="text-xl font-black text-gray-700 font-mono leading-none">{dateString}</span>
                        </div>

                        {/* Search Module */}
                        <div style={s.neuInset} className="flex-1 flex items-center px-4 gap-3 bg-gray-200/50">
                            <IconSearch />
                            <input
                                type="text"
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                placeholder="SEARCH PROTOCOL..."
                                className="bg-transparent w-full outline-none font-bold text-sm text-gray-600 placeholder-gray-400 font-mono"
                            />
                        </div>
                    </div>
                </div>

                {/* === DASHBOARD HERO (NEW CONTROL UNIT) === */}
                <div className="px-6 pb-2 flex flex-col items-center">
                    <DashboardControlUnit
                        progress={progress}
                        pending={tasks.length - doneCount}
                        criticalTask={criticalTask}
                    />
                </div>

                {/* === CONTROL BAR (FILTER) === */}
                <div className="px-6 mb-4">
                    <div style={s.neuInset} className="p-1.5 flex rounded-2xl">
                        {['All', 'Work', 'Personal'].map(filter => (
                            <button
                                key={filter}
                                onClick={() => setActiveFilter(filter)}
                                className={`flex-1 py-2.5 rounded-xl text-xs font-bold uppercase transition-all ${activeFilter === filter ? 'bg-[#E0E5EC] shadow-[4px_4px_8px_#B8B9BE,-4px_-4px_8px_#FFFFFF] text-[#6B46C1]' : 'text-gray-400 hover:text-gray-600'}`}
                            >
                                {filter}
                            </button>
                        ))}
                    </div>
                </div>

                {/* === TASK LIST STREAM === */}
                <div className="flex-1 px-6 pb-32 overflow-y-auto no-scrollbar space-y-4">
                    <div className="flex items-center justify-between mb-2 pl-1">
                        <h3 className="text-xs font-bold text-gray-400 uppercase tracking-widest">Active Sequence</h3>
                        <div style={s.ledOn} className="w-2 h-2 rounded-full animate-pulse"></div>
                    </div>

                    {filteredTasks.map(task => (
                        <TaskCartridge key={task.id} task={task} onToggle={() => toggleTask(task.id)} />
                    ))}

                    {/* Empty State Visual */}
                    {filteredTasks.length === 0 && (
                        <div style={s.neuInset} className="h-32 rounded-2xl flex flex-col items-center justify-center opacity-50 border-2 border-dashed border-gray-300">
                            <span className="text-gray-400 font-mono text-xs">NO_DATA_MATCH</span>
                        </div>
                    )}
                </div>

                {/* === BOTTOM ACTION BAR === */}
                <div className="absolute bottom-0 w-full p-6 pt-0 bg-gradient-to-t from-[#E0E5EC] to-transparent pointer-events-none flex justify-center">
                    <button
                        onClick={() => setIsSheetOpen(true)}
                        style={s.neuHard}
                        className="pointer-events-auto w-16 h-16 rounded-2xl flex items-center justify-center text-[#6B46C1] shadow-[8px_8px_16px_#B8B9BE,-8px_-8px_16px_#FFFFFF] active:shadow-[inset_4px_4px_8px_#B8B9BE,inset_-4px_-4px_8px_#FFFFFF] transition-all transform hover:-translate-y-1"
                    >
                        <IconBolt />
                    </button>
                </div>

                {/* === ADD TASK PANEL (Mechanical Sheet) === */}
                <div
                    className={`absolute inset-0 z-50 bg-black/20 backdrop-blur-[2px] transition-opacity duration-300 ${isSheetOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}
                    onClick={() => setIsSheetOpen(false)}
                >
                    <div
                        className={`
                 absolute bottom-0 w-full bg-[#E0E5EC] rounded-t-[40px] p-8 shadow-2xl transition-transform duration-300 ease-out flex flex-col max-h-[90vh]
                 ${isSheetOpen ? 'translate-y-0' : 'translate-y-full'}
               `}
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Handle */}
                        <div style={s.neuInset} className="w-16 h-2 rounded-full mx-auto mb-6 flex-shrink-0"></div>

                        <h2 className="text-xl font-black text-gray-700 uppercase tracking-tight mb-6 flex items-center gap-3 flex-shrink-0">
                            <span className="w-3 h-3 bg-purple-500 rounded-full"></span>
                            Initialize Task
                        </h2>

                        <div className="space-y-5 overflow-y-auto no-scrollbar pb-4">
                            {/* Input Field (Screen Style) */}
                            <div>
                                <label className="text-[10px] font-bold text-gray-400 uppercase ml-2 mb-1 block">Directive Title</label>
                                <div style={s.screenInset} className="p-1">
                                    <input
                                        autoFocus
                                        type="text"
                                        value={newTask.title}
                                        onChange={(e) => setNewTask({ ...newTask, title: e.target.value })}
                                        placeholder="ENTER_TASK_NAME..."
                                        className="w-full bg-transparent p-3 outline-none font-mono text-gray-600 font-bold placeholder-gray-400"
                                    />
                                </div>
                            </div>

                            {/* Description Area */}
                            <div>
                                <label className="text-[10px] font-bold text-gray-400 uppercase ml-2 mb-1 block">Details / Context</label>
                                <div style={s.screenInset} className="p-1">
                                    <textarea
                                        rows="3"
                                        value={newTask.description}
                                        onChange={(e) => setNewTask({ ...newTask, description: e.target.value })}
                                        placeholder="ENTER_DESCRIPTION..."
                                        className="w-full bg-transparent p-3 outline-none font-mono text-xs text-gray-600 font-medium placeholder-gray-400 resize-none"
                                    />
                                </div>
                            </div>

                            {/* Time & Deadline */}
                            <div className="flex gap-4">
                                <div className="flex-1">
                                    <label className="text-[10px] font-bold text-gray-400 uppercase ml-2 mb-1 block">Execution Time</label>
                                    <div style={s.neuHard} className="h-12 flex items-center justify-center font-bold text-gray-600 cursor-pointer overflow-hidden">
                                        <input
                                            type="time"
                                            value={newTask.time}
                                            onChange={(e) => setNewTask({ ...newTask, time: e.target.value })}
                                            className="bg-transparent text-center w-full h-full outline-none font-mono"
                                        />
                                    </div>
                                </div>
                                <div className="flex-1">
                                    <label className="text-[10px] font-bold text-gray-400 uppercase ml-2 mb-1 block">Deadline</label>
                                    <div style={s.neuHard} className="h-12 flex items-center justify-center font-bold text-gray-600 cursor-pointer overflow-hidden px-2">
                                        <input
                                            type="date"
                                            value={newTask.deadline}
                                            onChange={(e) => setNewTask({ ...newTask, deadline: e.target.value })}
                                            className="bg-transparent text-center w-full h-full outline-none font-mono text-xs uppercase"
                                        />
                                    </div>
                                </div>
                            </div>
                            {/* Priority Selection */}
                            <div>
                                <label className="text-[10px] font-bold text-gray-400 uppercase ml-2 mb-1 block">Priority Level</label>
                                <div className="flex gap-2">
                                    {['low', 'medium', 'high'].map(p => (
                                        <button
                                            key={p}
                                            onClick={() => setNewTask({ ...newTask, priority: p })}
                                            style={newTask.priority === p ? s.neuInset : s.neuHard}
                                            className={`flex-1 py-3 rounded-xl text-xs font-bold uppercase transition-all ${newTask.priority === p ? 'text-[#6B46C1] border border-purple-200' : 'text-gray-400'}`}
                                        >
                                            {p}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            <button
                                onClick={handleAddTask}
                                style={s.neuHard}
                                className="w-full py-5 rounded-2xl font-black text-[#6B46C1] uppercase tracking-widest mt-4 hover:bg-gray-50 transition-colors active:shadow-[inset_4px_4px_8px_#B8B9BE,inset_-4px_-4px_8px_#FFFFFF]"
                            >
                                Execute
                            </button>
                            <div className="h-4"></div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    );
}