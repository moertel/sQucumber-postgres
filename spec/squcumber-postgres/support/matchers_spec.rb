require_relative '../../spec_helper'
require_relative '../../../lib/squcumber-postgres/support/matchers'

module Squcumber
  describe 'MatcherHelpers' do
    let(:dummy_class) { Class.new { include MatcherHelpers } }

    before(:each) do
      allow(Date).to receive(:today).and_return Date.new(2017, 7, 15)
      allow(DateTime).to receive(:now).and_return DateTime.new(2017, 7, 15, 10, 20, 30)
    end

    describe '#convert_null_values' do
      context 'when no mapping is defined' do
        it 'leaves the original value as it is' do
          expect(dummy_class.new.convert_null_value('some_value', nil)).to eql('some_value')
        end
      end
      context 'when a mapping is defined' do
        context 'and the value matches the mapper' do
          it 'maps the value to nil' do
            expect(dummy_class.new.convert_null_value('some_value', 'some_value')).to eql(nil)
          end
        end
        context 'and the value does not match the mapper' do
          it 'maps the value to itself' do
            expect(dummy_class.new.convert_null_value('some_value', 'some_other_value')).to eql('some_value')
          end
        end
      end
    end

    describe '#values_match' do
      context 'when no null mapping is defined' do
        it 'always matches if there was no expectation' do
          actual = 'some_value'
          expected = nil
          expect(dummy_class.new.values_match(actual, expected)).to eql(true)
        end
        it 'never matches if the actual value is null' do
          actual = nil
          expected = 'some_value'
          expect(dummy_class.new.values_match(actual, expected)).to eql(false)
        end
      end
      context 'when some null mapping is defined' do
        it 'always matches if there was no expectation' do
          actual = 'some_value'
          expected = nil
          expect(dummy_class.new.values_match(actual, expected, null='whatever')).to eql(true)
        end
        it 'matches the set null placeholder' do
          actual = nil
          expected = 'some_value'
          null = 'some_value'
          expect(dummy_class.new.values_match(actual, expected, null=null)).to eql(true)
        end
        it 'does not match if the null placeholder does not match' do
          actual = nil
          expected = 'some_value'
          null = 'some_other_value'
          expect(dummy_class.new.values_match(actual, expected, null)).to eql(false)
        end
      end
    end

    describe '#convert_mock_values' do
      context 'with minute placeholders' do
        it 'sets minutes in the future' do
          expect(dummy_class.new.convert_mock_value('10 minutes from now')).to eql('2017-07-15T10:30:30+00:00')
        end
        it 'sets minutes in the past' do
          expect(dummy_class.new.convert_mock_value('10 minutes ago')).to eql('2017-07-15T10:10:30+00:00')
        end
        it 'sets hours in the future' do
          expect(dummy_class.new.convert_mock_value('9 hours from now')).to eql('2017-07-15T19:20:30+00:00')
        end
        it 'sets hours in the past' do
          expect(dummy_class.new.convert_mock_value('9 hours ago')).to eql('2017-07-15T01:20:30+00:00')
        end
      end
    end

    describe '#convert_mock_values' do
      context 'with day placeholders' do
        it 'sets today' do
          expect(dummy_class.new.convert_mock_value('today')).to eql('2017-07-15')
        end
        it 'sets tomorrow' do
          expect(dummy_class.new.convert_mock_value('tomorrow')).to eql('2017-07-16')
        end
        it 'sets yesterday' do
          expect(dummy_class.new.convert_mock_value('yesterday')).to eql('2017-07-14')
        end
        it 'travels into the past' do
          expect(dummy_class.new.convert_mock_value('10 days ago')).to eql('2017-07-05')
        end
        it 'travels into the future' do
          expect(dummy_class.new.convert_mock_value('30 days from now')).to eql('2017-08-14')
        end
        it 'converts to day' do
          expect(dummy_class.new.convert_mock_value('10 days from now (as day)')).to eql('25')
        end
        it 'converts to month' do
          expect(dummy_class.new.convert_mock_value('30 days from now (as month)')).to eql('8')
        end
        it 'converts to year' do
          expect(dummy_class.new.convert_mock_value('30 days from now (as year)')).to eql('2017')
        end
        it 'sets beginning of day' do
          expect(dummy_class.new.convert_mock_value('beginning of day 10 days from now')).to eql('2017-07-25')
        end
        it 'sets end of day' do
          expect(dummy_class.new.convert_mock_value('end of day 10 days from now')).to eql('2017-07-25')
        end
      end

      context 'with month placeholders' do
        context 'during a leap year' do
          it 'sets last month' do
            allow(Date).to receive(:today).and_return Date.new(2019, 3, 29)
            expect(dummy_class.new.convert_mock_value('last month')).to eql('2019-02-28')
          end
          it 'sets next month' do
            allow(Date).to receive(:today).and_return Date.new(2019, 1, 29)
            expect(dummy_class.new.convert_mock_value('next month')).to eql('2019-02-28')
          end
        end

        context 'when the length of months differ' do
          it 'travels into the past and keeps the day' do
            allow(Date).to receive(:today).and_return Date.new(2019, 3, 31)
            expect(dummy_class.new.convert_mock_value('2 month ago')).to eql('2019-01-31')
          end
          it 'travels into the future and keeps the day' do
            allow(Date).to receive(:today).and_return Date.new(2019, 1, 31)
            expect(dummy_class.new.convert_mock_value('2 months from now')).to eql('2019-03-31')
          end
          it 'sets beginning of month' do
            allow(Date).to receive(:today).and_return Date.new(2019, 1, 31)
            expect(dummy_class.new.convert_mock_value('beginning of month 9 months from now')).to eql('2019-10-01')
          end
          it 'sets end of month' do
            allow(Date).to receive(:today).and_return Date.new(2019, 1, 31)
            expect(dummy_class.new.convert_mock_value('end of month 9 months from now')).to eql('2019-10-31')
          end
        end

        it 'sets last month' do
          expect(dummy_class.new.convert_mock_value('last month')).to eql('2017-06-15')
        end
        it 'sets next month' do
          expect(dummy_class.new.convert_mock_value('next month')).to eql('2017-08-15')
        end
        it 'travels into the past' do
          expect(dummy_class.new.convert_mock_value('10 months ago')).to eql('2016-09-15')
        end
        it 'travels into the future' do
          expect(dummy_class.new.convert_mock_value('10 months from now')).to eql('2018-05-15')
        end
        it 'converts to day' do
          expect(dummy_class.new.convert_mock_value('10 months from now (as day)')).to eql('15')
        end
        it 'converts to month' do
          expect(dummy_class.new.convert_mock_value('10 months from now (as month)')).to eql('5')
        end
        it 'converts to year' do
          expect(dummy_class.new.convert_mock_value('10 months from now (as year)')).to eql('2018')
        end
        it 'sets beginning of month' do
          expect(dummy_class.new.convert_mock_value('beginning of month 10 months from now')).to eql('2018-05-01')
        end
        it 'sets end of month' do
          expect(dummy_class.new.convert_mock_value('end of month 10 months from now')).to eql('2018-05-31')
        end
      end

      context 'with year placeholders' do
        it 'sets last year' do
          expect(dummy_class.new.convert_mock_value('last year')).to eql('2016-07-15')
        end
        it 'sets next year' do
          expect(dummy_class.new.convert_mock_value('next year')).to eql('2018-07-15')
        end
        it 'travels into the past' do
          expect(dummy_class.new.convert_mock_value('10 years ago')).to eql('2007-07-15')
        end
        it 'travels into the future' do
          expect(dummy_class.new.convert_mock_value('10 years from now')).to eql('2027-07-15')
        end
        it 'converts to day' do
          expect(dummy_class.new.convert_mock_value('10 years from now (as day)')).to eql('15')
        end
        it 'converts to month' do
          expect(dummy_class.new.convert_mock_value('10 years from now (as month)')).to eql('7')
        end
        it 'converts to year' do
          expect(dummy_class.new.convert_mock_value('10 years from now (as year)')).to eql('2027')
        end
        it 'sets beginning of year' do
          expect(dummy_class.new.convert_mock_value('beginning of year 10 months from now')).to eql('2018-01-01')
        end
        it 'sets end of year' do
          expect(dummy_class.new.convert_mock_value('end of year 10 months from now')).to eql('2018-12-31')
        end
      end

      context 'with custom format' do
        it 'sets the date format' do
          expect(dummy_class.new.convert_mock_value('today (as custom \'%Y/%m/%d\')')).to eql('2017/07/15')
        end
      end
    end
  end
end
