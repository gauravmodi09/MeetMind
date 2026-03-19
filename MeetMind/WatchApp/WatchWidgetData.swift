import SwiftUI

/// Watch complication data views — designed for Apple Watch face
/// These render as compact watch-friendly views

// MARK: - Watch Meeting Complication

struct WatchMeetingComplication: View {
    let meetingCount: Int

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mic.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 108/255, green: 92/255, blue: 231/255))

            Text("\(meetingCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("meetings")
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Watch Todo Complication

struct WatchTodoComplication: View {
    let pendingCount: Int
    let todos: [WidgetTodo]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 108/255, green: 92/255, blue: 231/255))
                Text("\(pendingCount) tasks")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }

            ForEach(todos.prefix(3)) { todo in
                HStack(spacing: 4) {
                    Circle()
                        .fill(todo.priority == "high" ? Color.red : Color.orange)
                        .frame(width: 4, height: 4)
                    Text(todo.title)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.black)
    }
}

// MARK: - Watch Record Button

struct WatchRecordButton: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(red: 255/255, green: 71/255, blue: 87/255))
                    .frame(width: 44, height: 44)
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Record")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
