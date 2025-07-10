//
//  TabSelector.swift
//  safar
//
//  Created by Arman Kassam on 2025-07-07.
//
import SwiftUI

// Protocol that enums must conform to
protocol IconRepresentable {
    var icon: String { get }
}

struct TabBarView<T: CaseIterable & RawRepresentable & Hashable & IconRepresentable>: View
where T.AllCases: RandomAccessCollection, T.RawValue == String {
    
    @Binding var selectedCategory: T
    var iconSize: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let tabWidth = geometry.size.width / CGFloat(T.allCases.count)

            HStack(spacing: 0) {
                ForEach(Array(T.allCases), id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedCategory = tab
                        }
                    }) {
                        VStack(spacing: 0) {
                            VStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: iconSize))

                                Text(tab.rawValue)
                                    .font(.subheadline)
                                    .bold()
                            }
                            .frame(maxHeight: .infinity)

                            Rectangle()
                                .fill(selectedCategory == tab ? Color.accentColor : Color.clear)
                                .frame(height: 3)
                        }
                        .frame(width: tabWidth, height: 75) // Full height of tab
                        .foregroundColor(selectedCategory == tab ? .accentColor : .gray)
                    }
                }
            }
        }
        .frame(height: 80)
    }
}



//#Preview {
//    TabSelector()
//}
