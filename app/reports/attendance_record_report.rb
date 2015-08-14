# encoding: utf-8

require "prawn/measurement_extensions"

class AttendanceRecordReport
  include Prawn::View

  def self.build(entity_configuration, teacher, year, start_at, end_at, daily_frequencies)
    new.build(entity_configuration, teacher, year, start_at, end_at, daily_frequencies)
  end

  def initialize
    @document = Prawn::Document.new(page_size: 'A4',
                                    page_layout: :landscape,
                                    left_margin: 5.mm,
                                    right_margin: 5.mm,
                                    top_margin: 5.mm,
                                    bottom_margin: 5.mm)
  end

  def build(entity_configuration, teacher, year, start_at, end_at, daily_frequencies)
    @entity_configuration = entity_configuration
    @teacher = teacher
    @year = year
    @start_at = start_at
    @end_at = end_at
    @daily_frequencies = daily_frequencies

    header

    daily_frequencies_table

    footer

    self
  end

  private

  def header
    attendance_header = make_cell(content: 'Registro de frequência', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 5)
    begin
      logo_cell = make_cell(image: open(@entity_configuration.logo.url), fit: [50, 50], width: 70, rowspan: 4, position: :center, vposition: :center)
    rescue
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(content: "#{entity_name}\n#{organ_name}\n#{@daily_frequencies.first.unity.name}", size: 12, leading: 1.5, align: :center, valign: :center, rowspan: 4, padding: [6, 0, 8, 0])
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    year_header = make_cell(content: 'Ano letivo', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, width: 200, colspan: 2, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, width: 200, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    classroom_cell = make_cell(content: @daily_frequencies.first.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    year_cell = make_cell(content: @year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    perior_cell = make_cell(content: "De #{@start_at} a #{@end_at}", size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    discipline_cell = make_cell(content: (@daily_frequencies.first.discipline ? @daily_frequencies.first.discipline.description : 'Geral'), size: 10, colspan: 2, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    teacher_cell = make_cell(content: @teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)

    first_table_data = [[attendance_header],
                        [logo_cell, entity_organ_and_unity_cell, classroom_header, year_header, period_header],
                        [classroom_cell, year_cell, perior_cell],
                        [discipline_header, teacher_header],
                        [discipline_cell, teacher_cell]]

    repeat(:all) do
      table(first_table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def daily_frequencies_table
    sliced_daily_frequencies = @daily_frequencies.each_slice(40).to_a

    sliced_daily_frequencies.each_with_index do |daily_frequencies_slice, index|
      class_numbers = []
      days = []
      months = []
      students = {}
      daily_frequencies_slice.each do |daily_frequency|
        class_numbers << make_cell(content: "#{daily_frequency.class_number}", background_color: 'FFFFFF', align: :center)
        days << make_cell(content: "#{daily_frequency.frequency_date.day}", background_color: 'FFFFFF', align: :center)
        months << make_cell(content: "#{daily_frequency.frequency_date.month}", background_color: 'FFFFFF', align: :center)
        daily_frequency.students.each do |student|
          (students[student.student.id] ||= {})[:name] = student.student.name
          students[student.student.id][:absences] ||= 0
          if !student.present
            students[student.student.id][:absences] = students[student.student.id][:absences] + 1
          end
          (students[student.student.id][:attendances] ||= []) << make_cell(content: (student.present ? '.' : 'F'), font_style: :bold, align: :center)
        end
      end

      sequential_number_header = make_cell(content: 'Nº', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      student_name_header = make_cell(content: 'Nome do aluno', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      class_number_header = make_cell(content: 'Aula', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 20)
      day_header = make_cell(content: 'Dia', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      month_header = make_cell(content: 'Mês', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      absences_header = make_cell(content: 'Faltas', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)

      first_headers_and_class_numbers_cells = [sequential_number_header, student_name_header, class_number_header].concat(class_numbers)
      (40 - class_numbers.count).times { first_headers_and_class_numbers_cells << make_cell(content: '', background_color: 'FFFFFF') }
      first_headers_and_class_numbers_cells << absences_header
      days_header_and_cells = [day_header].concat(days)
      (40 - days.count).times { days_header_and_cells << make_cell(content: '', background_color: 'FFFFFF') }
      months_header_and_cells = [month_header].concat(months)
      (40 - months.count).times { months_header_and_cells << make_cell(content: '', background_color: 'FFFFFF') }

      students_cells = []
      students.each_with_index do |(key, value), index|
        sequence_cell = make_cell(content: (index + 1).to_s, align: :center)
        student_cells = [sequence_cell, { content: value[:name], colspan: 2 }].concat(value[:attendances])
        (40 - value[:attendances].count).times { student_cells << nil }
        student_cells << make_cell(content: value[:absences].to_s, align: :center)
        students_cells << student_cells
      end

      (30 - students_cells.count).times do
        sequence_cell = make_cell(content: (students_cells.count + 1).to_s, align: :center)
        attendances = []
        40.times { attendances << make_cell(content: '', font_style: :bold, align: :center) }
        student_cells = [sequence_cell, { content: '', colspan: 2 }].concat(attendances)
        student_cells << make_cell(content: '', align: :center)
        students_cells << student_cells
      end

      sliced_students_cells = students_cells.each_slice(30).to_a
      sliced_students_cells.each_with_index do |students_cells_slice, index|
        data = [
          first_headers_and_class_numbers_cells,
          days_header_and_cells,
          months_header_and_cells
        ]
        data.concat(students_cells_slice)

        column_widths = { 0 => 20, 1 => 140, 43 => 30 }
        (3..42).each { |i| column_widths[i] = 13 }

        bounding_box([0, 482], width: bounds.width) do
          table(data, row_colors: ['FFFFFF', 'DEDEDE'], cell_style: { size: 8, padding: [2, 2, 2, 2] }, column_widths: column_widths, width: bounds.width) do |t|
            t.cells.border_width = 0.25
            t.before_rendering_page do |page|
              page.row(0).border_top_width = 0.25
              page.row(-1).border_bottom_width = 0.25
              page.column(0).border_left_width = 0.25
              page.column(-1).border_right_width = 0.25
            end
          end
        end

        start_new_page if index < sliced_students_cells.count - 1
      end

      start_new_page if index < sliced_daily_frequencies.count - 1
    end
  end

  def footer
    repeat(:all) do
      draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [0, 0])
      draw_text('______________________________', size: 8, at: [118, 0])

      draw_text('Data:', size: 8, style: :bold, at: [275, 0])
      draw_text('____________________', size: 8, at: [298, 0])
    end

    string = "Página <page> de <total>"
    options = { at: [bounds.right - 150, 6],
                width: 150,
                size: 8,
                align: :right }
    number_pages(string, options)
  end
end