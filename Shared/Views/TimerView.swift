//
//  TimerView.swift
//  Cubing Timer
//
//  Created by Cameron Delong on 8/16/21.
//

import SwiftUI

/// A view for timing solves.
struct TimerView: View {
    // MARK: Properties
    /// The state of the timer.
    @Binding var timerState: TimerState
    
    /// A callback that is called when a the timer is stopped, with the time on the timer.
    let timerStoppedAction: (_ time: Double) -> Void
    
    /// A stopwatch to time solves.
    @StateObject var stopwatch = Stopwatch()
    /// A countdown to start timing solves.
    @StateObject var countdown: Countdown
    /// A timer for inspection.
    @StateObject var inspection: Inspection
    
    /// Whether inspection should be timed before the timer starts.
    let doInspection: Bool
    
    /// The duration of the `TimerView`'s inspection.
    @Binding var inspectionDuration: Int?
    
    /// The `TimerView`'s most recent time.
    @ObservedOptionalObject private var solve: Solve?
    
    /// The horizontal size of the view.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    /// The size of the timer text.
    @State private var textSize: CGSize = CGSize(width: 0, height: 0)
    
    /// Whether the value of `solve` changed since the timer started.
    @State private var solveChanged = true
    
    /// The displayed time.
    private var timerText: String {
        if timerState == .ready {
            return doInspection ? String(inspection.duration) : "0.0"
        } else if timerState == .inspection {
            return Solve.formatTime(Double(inspection.secondsRemaining), places: 0, secondsOnly: true)
        } else if timerState == .running {
            return Solve.formatTime(stopwatch.secondsElapsed, places: 1)
        } else {
            return solve != nil ? Solve.formatTime(solve!.adjustedTime) : "0.00"
        }
    }
    
    /// The color of the timer text.
    private var timeColor: Color {
        if timerState == .running || timerState == .ready || timerState == .inspection {
            return .white
        } else if timerState == .counting {
            return .yellow
        } else if solve?.penalty == .dnf {
            return .secondary
        } else {
            return .primary
        }
    }
    
    // MARK: Initializers
    init(timerState: Binding<TimerState>, solve: Solve? = nil, countdownDuration: Double = 0.5, inspectionDuration: Binding<Int?> = .constant(15), timerStoppedAction: @escaping (_ time: Double) -> Void) {
        self._timerState = timerState
        
        self.timerStoppedAction = timerStoppedAction
        
        self._solve = ObservedOptionalObject(initialValue: solve)
        
        _countdown = StateObject(wrappedValue: Countdown(duration: countdownDuration))
        _inspection = StateObject(wrappedValue: Inspection(duration: inspectionDuration.wrappedValue ?? 15))
        
        doInspection = inspectionDuration.wrappedValue != nil
        self._inspectionDuration = inspectionDuration
    }
    
    // MARK: Body
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: solve?.penalty == .dnf && solveChanged ? textSize.width : 0, height: 5)
                .shadow(radius: 5)
                .opacity(timerState == .stopped ? 1 : 0)
                .animation(.default, value: timerState == .stopped)
            
            Text(timerText)
                .foregroundColor(.white)
                .colorMultiply(timeColor)
                .animation(.default, value: timeColor)
                .animation(nil)
                .scaleEffect()
                .font(.system(size: 100, design: .monospaced))
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .if(horizontalSizeClass == .compact) { view in
                    view.padding(.vertical, -textSize.height / 6)
                }
                .if(horizontalSizeClass == .regular) { view in
                    view.padding(.vertical, -20)
                }
                .readSize(size: $textSize)
                .onChange(of: countdown.complete) { isComplete in
                    if isComplete {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.5)) {
                            timerState = .ready
                        }
                        
                        Haptics.shared.pop()
                    }
                }
                .onChange(of: timerState) { [timerState] newValue in
                    switch newValue {
                    case .stopped:
                        if timerState == .running {
                            try? stopwatch.stop()
                            
                            timerStoppedAction(stopwatch.secondsElapsed)
                        } else if timerState == .inspection {
                            try? inspection.reset()
                        } else {
                            try? countdown.reset()
                        }
                    case .counting:
                        try? countdown.start()
                    case .inspection:
                        try? countdown.reset()
                        
                        try? inspection.start()
                    case .running:
                        stopwatch.reset()
                        
                        try? countdown.reset()
                        
                        try? inspection.reset()
                        
                        try? stopwatch.start()
                        
                        solveChanged = false
                    default:
                        break
                    }
                }
                .onChange(of: inspectionDuration) { inspectionDuration in
                    inspection.duration = inspectionDuration ?? 15
                }
                .onChange(of: solve) { _ in
                    solveChanged = true
                }
        }
    }
    
    /// Possible states of a `TimerView`.
    enum TimerState {
        /// The timer is stopped.
        case stopped
        /// The timer is counting until it's ready.
        case counting
        /// Inspection is being counted
        case inspection
        /// The timer is ready to start.
        case ready
        /// The timer is running
        case running
    }
}
