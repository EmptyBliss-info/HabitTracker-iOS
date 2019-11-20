//
//  HabitController.swift
//  Habit Tracker
//
//  Created by Lambda_School_Loaner_214 on 11/18/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData

enum DayStatus: Int16 {
    case yes = 1
    case no = -1
    case unset = 0
}

class HabitController {
    static let shared = HabitController()
    
    private init() {
        
    }
    
    @discardableResult func add(title: String, desc: String, goalDays: Int) -> Habit{
        let habit = Habit(title: title, desc: desc, goalDays: goalDays)
        //addDay(habit: habit)
        CoreDataStack.shared.save()
        return habit
    }
    
    func update(habit: Habit, title: String, desc: String, goalDays: Int) {
        habit.title = title
        habit.desc = desc
        habit.goalDays = Int64(goalDays)
        CoreDataStack.shared.save()
    }
    
    func delete(habit: Habit) {
        CoreDataStack.shared.mainContext.delete(habit)
        CoreDataStack.shared.save()
    }
    
    func addDay (habit: Habit) -> Day {
        let day = Day(habit: habit)
        CoreDataStack.shared.save()
        return day
    }
}
