module ExamPoster
  class NumericalExamPoster < Base
    def self.post!(post_data)
      new(post_data).post!
    end

    def post!
      post_by_classrooms.each do |classroom_id, classroom_score|
        classroom_score.each do |student_id, student_score|
          student_score.each do |discipline_id, discipline_score|
            api.send_post(notas: { classroom_id => { student_id => { discipline_id => discipline_score } } }, etapa: @post_data.school_calendar_step.to_number, resource: 'notas')
          end
        end
      end
      return { warning_messages: @warning_messages }
    end

    def post_by_classrooms
      scores = Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) }

      classroom_ids = teacher.teacher_discipline_classrooms.pluck(:classroom_id).uniq

      classroom_ids.each do |classroom|
        teacher_discipline_classrooms = teacher.teacher_discipline_classrooms.where(classroom_id: classroom)

        teacher_discipline_classrooms.each do |teacher_discipline_classroom|
          classroom = teacher_discipline_classroom.classroom
          discipline = teacher_discipline_classroom.discipline

          next if !correct_score_type(classroom.exam_rule.score_type)
          next if !same_unity(classroom.unity_id)

          teacher_score_fetcher = TeacherScoresFetcher.new(teacher, classroom, discipline, @post_data.school_calendar_step)
          teacher_score_fetcher.fetch!

          student_scores = teacher_score_fetcher.scores

          student_scores.each do |student_score|
            value = StudentAverageCalculator.new(student_score).calculate(discipline.id, @post_data.school_calendar_step.id)
            scores[classroom.api_code][student_score.api_code][discipline.api_code]['valor'] = value
          end
          @warning_messages += teacher_score_fetcher.warning_messages if teacher_score_fetcher.has_warnings?
        end
      end
      return scores
    end

    private

    def api
      IeducarApi::PostExams.new(@post_data.to_api)
    end

    def teacher
      @post_data.author.teacher
    end

    def same_unity(unity_id)
      unity_id == @post_data.school_calendar_step.school_calendar.unity_id
    end

    def correct_score_type(score_type)
      score_type == ScoreTypes::NUMERIC
    end
  end
end