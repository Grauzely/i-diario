class PartialScoreRecordReportController < ApplicationController
  before_action :require_current_school_calendar
  before_action :require_current_test_setting

  def form
    @partial_score_record_report_form = PartialScoreRecordReportForm.new
    @partial_score_record_report_form.classroom_id = current_user.current_classroom_id
    @partial_score_record_report_form.school_calendar_year = current_school_calendar.year
  end

  def report
    @partial_score_record_report_form = PartialScoreRecordReportForm.new(resource_params)

    if @partial_score_record_report_form.valid?
      partial_score_record_report = PartialScoreRecordReport.build(current_entity_configuration,
                                                  current_school_calendar.year,
                                                  @partial_score_record_report_form.step,
                                                  @partial_score_record_report_form.student,
                                                  @partial_score_record_report_form.unity,
                                                  @partial_score_record_report_form.classroom)

      send_data(partial_score_record_report.render, filename: 'registro-de-notas-parciais.pdf', type: 'application/pdf', disposition: 'inline')
    else
      @partial_score_record_report_form.school_calendar_year = current_school_calendar.year
      render :form
    end
  end

  private

  def school_calendar_steps
    @school_calendar_steps ||= SchoolCalendarStep.where(school_calendar: current_school_calendar)
  end
  helper_method :school_calendar_steps


  def school_calendar_steps_ordered
    school_calendar_steps.ordered
  end
  helper_method :school_calendar_steps_ordered

  def school_calendar_classroom_steps
    @school_calendar_classroom_steps ||= SchoolCalendarClassroomStep.by_classroom(current_user_classroom)
  end
  helper_method :school_calendar_classroom_steps

  def students
    @students ||= Student.where(id: DailyNoteStudent.by_classroom_id(@partial_score_record_report_form.classroom_id)
                                                    .by_test_date_between(current_school_calendar.first_day, current_school_calendar.last_day)
                                                    .select(:student_id)).ordered
  end
  helper_method :students

  def classrooms
    @classrooms ||= Classroom.by_unity(current_user.current_unity).by_year(current_school_calendar.year).ordered
  end
  helper_method :classrooms

  def resource_params
    params.require(:partial_score_record_report_form).permit(:unity_id,
                                                            :classroom_id,
                                                            :student_id,
                                                            :school_calendar_step_id,
                                                            :school_calendar_classroom_step_id)
  end
end