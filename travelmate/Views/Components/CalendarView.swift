import SwiftUI
import Foundation

struct AvailabilityCalendarView: View {
    let destinationId: String
    @Binding var selectedStartDate: Date
    @Binding var selectedEndDate: Date
    @StateObject private var reservationService = ReservationService()
    @State private var existingReservations: [Reservation] = []
    @State private var currentMonth = Date()
    @State private var selectionState: SelectionState = .none
    @State private var errorMessage: String?
    
    enum SelectionState {
        case none
        case startSelected
        case bothSelected
    }
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 20) {
            // En-tête du calendrier
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Jours de la semaine
            HStack {
                ForEach(["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Message d'erreur
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            // Grille du calendrier
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayView(
                            date: date,
                            isSelected: isDateInRange(date),
                            isReserved: isDateReserved(date),
                            isToday: calendar.isDateInToday(date),
                            onTap: { selectDate(date) }
                        )
                    } else {
                        // Cellule vide pour aligner le calendrier
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            // Instructions de sélection
            Text(getSelectionInstructions())
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Légende
            HStack(spacing: 20) {
                LegendItem(color: .white, text: "Disponible")
                LegendItem(color: .gray.opacity(0.5), text: "Sélectionné")
                LegendItem(color: .red.opacity(0.7), text: "Réservé")
            }
            .padding()
        }
        .onAppear {
            // Réinitialiser les dates par défaut
            resetSelection()
            Task {
                await loadReservations()
            }
        }
        .onChange(of: currentMonth) { _ in
            Task {
                await loadReservations()
            }
        }
    }
    
    private func getSelectionInstructions() -> String {
        switch selectionState {
        case .none:
            return "Sélectionnez votre date de départ"
        case .startSelected:
            return "Sélectionnez votre date de fin"
        case .bothSelected:
            return "Appuyez sur une nouvelle date pour recommencer la sélection"
        }
    }
    
    private func resetSelection() {
        selectionState = .none
        errorMessage = nil
        // Réinitialiser à des dates nulles (ou aujourd'hui)
        let today = Date()
        selectedStartDate = today
        selectedEndDate = today
    }
    
    private func changeMonth(_ direction: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let numberOfDays = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)
        
        var days: [Date?] = []
        
        // Ajouter des cellules vides pour aligner le premier jour
        let emptyDays = (weekdayOfFirstDay == 1) ? 6 : weekdayOfFirstDay - 2
        for _ in 0..<emptyDays {
            days.append(nil)
        }
        
        // Ajouter tous les jours du mois
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func selectDate(_ date: Date) {
        errorMessage = nil
        
        switch selectionState {
        case .none:
            // Premier clic : sélectionner la date de départ
            selectedStartDate = date
            selectedEndDate = date
            selectionState = .startSelected
            
        case .startSelected:
            // Deuxième clic : sélectionner la date de fin
            if date >= selectedStartDate {
                selectedEndDate = date
                // Vérifier s'il y a des dates réservées dans la plage
                if hasReservedDatesInRange(start: selectedStartDate, end: selectedEndDate) {
                    errorMessage = "Il y a des dates déjà réservées dans votre sélection. Veuillez choisir d'autres dates."
                    resetSelection()
                } else {
                    selectionState = .bothSelected
                }
            } else {
                // Si la date est antérieure, recommencer
                selectedStartDate = date
                selectedEndDate = date
                selectionState = .startSelected
            }
            
        case .bothSelected:
            // Troisième clic ou plus : recommencer la sélection
            resetSelection()
            selectedStartDate = date
            selectedEndDate = date
            selectionState = .startSelected
        }
    }
    
    private func hasReservedDatesInRange(start: Date, end: Date) -> Bool {
        let calendar = Calendar.current
        var currentDate = start
        
        while currentDate <= end {
            if isDateReserved(currentDate) {
                return true
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return false
    }
    
    private func isDateInRange(_ date: Date) -> Bool {
        guard selectionState != .none else { return false }
        
        let startOfDay = calendar.startOfDay(for: date)
        let startOfSelectedStart = calendar.startOfDay(for: selectedStartDate)
        let startOfSelectedEnd = calendar.startOfDay(for: selectedEndDate)
        
        return startOfDay >= startOfSelectedStart && startOfDay <= startOfSelectedEnd
    }
    
    private func isDateReserved(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        
        for reservation in existingReservations {
            if let startDate = ISO8601DateFormatter().date(from: reservation.startDate),
               let endDate = ISO8601DateFormatter().date(from: reservation.endDate) {
                let reservationStart = calendar.startOfDay(for: startDate)
                let reservationEnd = calendar.startOfDay(for: endDate)
                
                if startOfDay >= reservationStart && startOfDay < reservationEnd {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func loadReservations() async {
        existingReservations = await reservationService.getDestinationReservations(destinationId: destinationId)
    }
}

struct DayView: View {
    let date: Date
    let isSelected: Bool
    let isReserved: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .disabled(isReserved || date < Date())
    }
    
    private var backgroundColor: Color {
        if isReserved {
            return .red.opacity(0.7)
        } else if isSelected {
            return .gray.opacity(0.5)
        } else {
            return .white
        }
    }
    
    private var textColor: Color {
        if isReserved {
            return .white
        } else if date < Date() {
            return .gray.opacity(0.5)
        } else {
            return .primary
        }
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
} 