//
//  InstanceList.swift
//  Cubing Timer
//
//  Created by Cameron Delong on 8/7/21.
//

import SwiftUI

/// A list of `Instance`s.
struct InstanceList: View {
    // MARK: Properties
    /// All of the `Instance`s to display.
    var instances: FetchedResults<Instance>
    
    /// Whether the sheet to add a new instance is displayed.
    @State private var showingAddInstanceSheet = false
    
    // MARK: Body
    var body: some View {
        List {
            ForEach(instances, id: \.id) { instance in
                NavigationLink(destination: InstanceView(instance: instance)) {
                    InstanceRow(instance: instance)
                }
            }
            .onDelete(perform: InstanceStorage.delete)
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Instances")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddInstanceSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingAddInstanceSheet) {
            AddInstanceSheet { name, puzzle, notes, inspectionDuration in
                InstanceStorage.add(
                    name: name,
                    puzzle: puzzle,
                    notes: notes,
                    inspectionDuration: inspectionDuration
                )
            }
        }
    }
}
